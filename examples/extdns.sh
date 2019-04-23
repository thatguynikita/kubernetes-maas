export PARENT_ZONE=example.com
export ZONE=k8s.example.com

# create the hosted zone for the subdomain
aws route53 create-hosted-zone --name ${ZONE} --caller-reference "$ZONE-$(uuidgen)"

# capture the zone ID
export ZONE_ID=$(aws route53 list-hosted-zones | jq -r ".HostedZones[]|select(.Name == \"${ZONE}.\")|.Id")

# create a changeset template
cat >update-zone.template.json <<EOL
{
  "Comment": "Create a subdomain NS record in the parent domain",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "",
      "Type": "NS",
      "TTL": 300,
      "ResourceRecords": []
    }
  }]
}
EOL

# generate the changeset for the parent zone
cat update-zone.template.json \
 | jq ".Changes[].ResourceRecordSet.Name=\"${ZONE}.\"" \
 | jq ".Changes[].ResourceRecordSet.ResourceRecords=$(aws route53 get-hosted-zone --id ${ZONE_ID} | jq ".DelegationSet.NameServers|[{\"Value\": .[]}]")" > update-zone.json

# create a NS record for the subdomain in the parent zone
aws --profile << AWS profile >> route53 change-resource-record-sets \
  --hosted-zone-id $(aws route53 list-hosted-zones | jq -r ".HostedZones[] | select(.Name==\"$PARENT_ZONE.\") | .Id" | sed 's/\/hostedzone\///') \
  --change-batch file://update-zone.json
