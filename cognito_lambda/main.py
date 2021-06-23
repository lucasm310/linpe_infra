import json
import boto3

def lambda_handler(event, context):
    region = event["region"]
    user_pool = event["userPoolId"]
    username = event["userName"]
    boto3.setup_default_session(region_name=region)
    client = boto3.client('cognito-idp')
    client.admin_add_user_to_group(
        UserPoolId=user_pool,
        Username=username,
        GroupName="geral"
    )
    return event
