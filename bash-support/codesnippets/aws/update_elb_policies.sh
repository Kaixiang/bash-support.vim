set -e

export AWS_ACCESS_KEY_ID=$BOSH_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$BOSH_AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=us-east-1

#FIXME
replace_policy=ELBSecurityPolicy-2011-08
to_policy=ELBSecurityPolicy-2014-01

# Find out the elbs list needed to update
elbs_2_change=`aws elb describe-load-balancers | jq -r "[select(.LoadBalancerDescriptions[].ListenerDescriptions[].PolicyNames[]|contains(\"$replace_policy\"))|.LoadBalancerDescriptions[].LoadBalancerName]|unique[]"`

echo "below elb contain old policy $replace_policy needed to change to $to_policy"
echo $elbs_2_change

sleep 5

for e in $elbs_2_change
do
  ports_2_change=`aws elb describe-load-balancers --load-balancer-names $e|jq .LoadBalancerDescriptions[].ListenerDescriptions[]|jq "select (.PolicyNames[]|contains(\"$replace_policy\"))|.Listener.LoadBalancerPort"`
  for p in $ports_2_change
  do
    echo "replacing elb $e policy for port $p"
    sleep 5
    aws elb set-load-balancer-policies-of-listener --load-balancer-name $e --load-balancer-port $p --policy-names "$to_policy"
  done
done
