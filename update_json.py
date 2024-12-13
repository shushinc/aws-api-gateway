import json
import sys
# File path
file_path = "./templates/sherlock-api-export.json"

# ARN from command-line argument
arn = sys.argv[1]

# arn = "${aws_cognito_user_pool.sherlock_userpool5.arn}"

# Read the JSON file
with open(file_path, "r") as file:
    content = file.read()

# Replace the placeholder with the actual ARN
content = content.replace('${cognito_user_pool_arn}', arn)


# Write the updated content back to the file
with open(file_path, "w") as file:
    file.write(content)