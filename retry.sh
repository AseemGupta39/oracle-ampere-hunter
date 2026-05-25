#!/bin/bash

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
  --image-id "$(oci compute image list \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --operating-system "Canonical Ubuntu" \
    --operating-system-version "22.04" \
    --shape VM.Standard.A1.Flex \
    --query 'data[0].id' \
    --raw-output)"

  if [ $? -eq 0 ]; then
    echo "SUCCESS!"
    curl -s -X POST "https://ntfy.sh/$NTFY_TOPIC" \
      -d "OCI Ampere instance created!"    
    exit 0
  fi

  echo "Retrying in 90 seconds..."
  sleep 90
done
