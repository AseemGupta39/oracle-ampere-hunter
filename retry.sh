#!/bin/bash

IMAGE_ID=$(oci compute image list \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --operating-system "Canonical Ubuntu" \
  --operating-system-version "24.04" \
  --shape VM.Standard.A1.Flex \
  --query 'data[0].id' \
  --raw-output)

echo "Using latest Ubuntu 24 image: $IMAGE_ID"

while true
do
  echo "Trying at $(date)..."

  oci compute instance launch \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --availability-domain "$OCI_AD" \
    --shape VM.Standard.A1.Flex \
    --subnet-id "$OCI_SUBNET_ID" \
    --assign-public-ip true \
    --shape-config '{"ocpus":1,"memoryInGBs":2}' \
    --display-name ampere-free-test \
    --image-id "$IMAGE_ID"
    
  if [ $? -eq 0 ]; then
    echo "SUCCESS! Tiny instance created."

    curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
      -d "instance created now going for autoscaling"
  
    INSTANCE_ID=$(oci compute instance list \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --query 'data[0].id' \
      --raw-output)
  
    echo "Trying immediate scale to 4 OCPU / 24 GB..."
  
    oci compute instance update \
      --instance-id "$INSTANCE_ID" \
      --shape-config '{"ocpus":4,"memoryInGBs":24}'
  
    if [ $? -eq 0 ]; then
      MESSAGE="SUCCESS! Scaled to 4 OCPU / 24 GB 🚀"
      curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
        -d "autoscaling successfull u have 4 core 24 gb ram"
    else
      MESSAGE="Tiny instance created, scale-up failed. Keeping 1 OCPU / 2 GB."
      curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
        -d "autoscaling failed stay there"
    fi
  
    exit 0
fi

  # if [ $? -eq 0 ]; then
  #   echo "SUCCESS!"

  #   curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
  #     -d "OCI Ampere instance created!"

  #   exit 0
  # fi

  sleep 90
done
