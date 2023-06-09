#!/bin/bash

REPO="monitoring"


import_containers() {

    echo "Starting container imports"
    for image in $(cat containers);
    do
        if [ $image == "::SOCK_SHOP::" ]; then
            REPO="sock-shop"
            continue
        fi

        docker pull $image ;

        docker tag $image $LOCATION-docker.pkg.dev/$PROJECT_ID/$REPO/$(echo $image | rev | cut -d":" -f2 | cut -d"/" -f1 | rev):$(echo $image | cut -d":" -f2 );
        docker push $LOCATION-docker.pkg.dev/$PROJECT_ID/$REPO/$(echo $image | rev | cut -d":" -f2 | cut -d"/" -f1 | rev):$(echo $image | cut -d":" -f2 );
    done

    exit 0

}

case $1 in
    import)
	gcloud artifacts docker images describe $LOCATION-docker.pkg.dev/$PROJECT_ID/sock-shop/user 2>/dev/null	
	if [ $? != 0 ]; then
	    import_containers
	fi
	exit 0
    ;;
esac


