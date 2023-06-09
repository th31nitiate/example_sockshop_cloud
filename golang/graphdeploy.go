// Package helloworld provides a set of Cloud Functions samples.cloudfunctions.googleapis.com
package graphdeploy

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"github.com/grafana-tools/sdk"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

var (
	rawBoard       []byte
	err            error
	kubeconfig     string
	basicAuthCheck bool = false
	namespace      string
	returnIP       bool = true
	publicIP       bool
	label          string
)

func init() {
	// We register this funaction here, this means it made avalible to the serverless platform
	functions.CloudEvent("PubSubTrigger", pubSubTrigger)
}

type MessagePublishedData struct {
	Message PubSubMessage
}

type PubSubMessage struct {
	Data []byte `json:"data"`
}

type deepModTransport struct {
	Tr http.RoundTripper
}

func resp(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "200 ok")
}

func pubSubTrigger(ctx context.Context, e event.Event) error {

	// This is not generally need but if we wish to run this on kubernetes
	// It generally helps to have health check associated with the function
	go func() {
		http.HandleFunc("/", resp)
		http.ListenAndServe(":8080", nil)
	}()

	// We handle the message and can extend the code to support a whole lot
	// more options based on messages received from pubsub events
	eventMsg, err := handlePubSubMsg(e)
	if err != nil {
		fmt.Printf("Error: %s", err)
	}

	switch eventMsg {
	case "SVCDEPLOYED":
		run_svc()
	case "HELLO":
		log.Printf("World hello")
	default:
		log.Printf("Error unknown value: ", eventMsg)
		os.Exit(1)
	}

	return nil
}

// Function handles messages passed to it as events directly from pubsub
// we can also perform various error handling and message filtering here
func handlePubSubMsg(pubSubEven event.Event) (string, error) {
	var msg MessagePublishedData
	if err := pubSubEven.DataAs(&msg); err != nil {
		return "", error(fmt.Errorf("event.DataAs: %w", err))
	}

	return string(msg.Message.Data), nil
}

// This is out main function for dealing with valid requests that we get for this use case
func run_svc() {

	// create kubeclient which is an authenticated object we can use
	// for making API calls to a remote kube cluster
	kubeClient := getKubeClient()

	// Check and verify pod is in running state and retrive IP information for grafana data source configuration
	namespace = "monitoring"
	podKRunning, prometheusPodIP, err := waitUntilPodReady(kubeClient, namespace, "app=prometheus", returnIP, false)
	if err != nil {
		fmt.Println("Error: ", err, podKRunning)
	}

	// Check grafana is running and retrieve public IP for auth reasons
	podGRunning, grafanaPodIP, err := waitUntilPodReady(kubeClient, namespace, "app=grafana", returnIP, true)
	if err != nil {
		fmt.Println("Error: ", err, podGRunning)
	}

	// Create client for authenticating API requests
	grafanaClient := getGrafanaClient(grafanaPodIP)

	// Provision the required dashboards
	uploadDashboad(grafanaClient, "./serverless_function_source_code/kube_file_new.json", prometheusPodIP)

}

// Check pod are running and waits if their not until running or error if there is a start up issue
// It will return IP address either clusterIP or LoadBalancerIP
func waitUntilPodReady(kubeClient *kubernetes.Clientset, nameSpace string, selector string, ipReturn bool, publicIP bool) (bool, string, error) {

	for {
		pod, err := kubeClient.CoreV1().Pods(nameSpace).List(context.TODO(), metav1.ListOptions{LabelSelector: selector})
		if err != nil {
			return false, "", err
		}

		// Check retrieved pods are valid by ensuring the list is more than one
		// Take the first pod as there should be only one pod based on selector
		if len(pod.Items) > 0 {
			targetPod := pod.Items[0]

			// Check the status of the pod is  in in running state
			if targetPod.Status.Phase == corev1.PodRunning {
				fmt.Println("Pod is surely running")

				// Verify method for retrieving pod information
				if ipReturn == true && publicIP == false {
					return true, targetPod.Status.PodIP, nil
				} else if ipReturn == true && publicIP == true {

					// If public IP required then ensure to get a list of services then extract the public IP
					svc, err := kubeClient.CoreV1().Services(namespace).List(context.TODO(), metav1.ListOptions{LabelSelector: "app=grafana"})
					if err != nil {
						fmt.Println("Error: ", err)
						return false, "", nil
					}

					return true, svc.Items[0].Status.LoadBalancer.Ingress[0].IP, nil
				}
				return true, "", nil
			}
		} else {
			continue
		}

	}
}

func uploadDashboad(client *sdk.Client, fileName string, promPodIP string) {

	promPodIP = fmt.Sprintf("http://%s:9090", promPodIP)

	// Generate data source variables by using a struct
	datasourceParams := sdk.Datasource{
		Name:      "prometheus",
		Type:      "prometheus",
		URL:       promPodIP, // Ensure to format url accordingly
		Access:    "proxy",
		BasicAuth: &basicAuthCheck,
	}

	// use the grafana client to create the data source by sending the request to grafana
	statusMsg, err := client.CreateDatasource(context.TODO(), datasourceParams)
	if err != nil {
		fmt.Println(err, statusMsg)
	} else {
		fmt.Println("Data source created successfully")
	}

	// We read in the raw dash board from its location then perform formatting on it
	rawBoard, err = os.ReadFile(fileName)
	if err != nil {
		fmt.Println(err)
	}

	var board sdk.Board
	if err = json.Unmarshal(rawBoard, &board); err != nil {
		fmt.Println(err)
	}

	if _, err = client.DeleteDashboard(context.Background(), board.UpdateSlug()); err != nil {
		fmt.Println(err)
	}

	params := sdk.SetDashboardParams{
		FolderID:  sdk.DefaultFolderId,
		Overwrite: false,
	}

	rtdn, err := client.SetDashboard(context.TODO(), board, params)
	if err != nil {
		fmt.Println("Error on importing dashboard ", err, board.Title, rtdn)
	} else {
		fmt.Println("Success adding dashboard")
	}

}

func getKubeClient() *kubernetes.Clientset {

	kubeconfig = fmt.Sprintf("/config/%s", "kubeconfig")

	config, _ := clientcmd.BuildConfigFromFlags("", kubeconfig)

	kubeClient, _ := kubernetes.NewForConfig(config)
	if err != nil {
		log.Printf("Failed to create a client: %s\n", err)
		os.Exit(1)
	}

	return kubeClient
}

func (tr *deepModTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Add("User-Agent", "graphDeploy")
	req.Header.Add("Host", "mysvc.foo.org") // This is a bug that can be updated on the server side
	return tr.Tr.RoundTrip(req)
}

func initTransport(Tr http.RoundTripper) *deepModTransport {
	if Tr == nil {
		Tr = &http.Transport{

			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
		}
	}
	return &deepModTransport{Tr}
}

func getGrafanaClient(host string) *sdk.Client {

	var defaultPassword string = "admin:admin"

	httpClient := &http.Client{Timeout: 2 * time.Second, Transport: initTransport(nil)}

	grafanaClient, err := sdk.NewClient(fmt.Sprintf("http://%s", host), defaultPassword, httpClient)
	if err != nil {
		log.Printf("Failed to create a client: %s\n", err)
		os.Exit(1)
	}

	return grafanaClient
}
