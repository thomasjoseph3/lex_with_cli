#!/bin/bash

# Set your variables
BOT_ID=""             # Your hardcoded bot ID
LOCALE_ID="en_US"                # Bot locale
KNOWLEDGE_BASE_ID=""   # Your knowledge base ID
REGION="eu-west-2"               # AWS region
ACCOUNT_ID=""        # Your AWS account ID (from your Serverless YAML)
BOT_VERSION="DRAFT"              # Lex bot version

# Construct the full ARN for the knowledge base
KNOWLEDGE_BASE_ARN="arn:aws:bedrock:$REGION:$ACCOUNT_ID:knowledge-base/$KNOWLEDGE_BASE_ID"

# Create QnAIntent configuration file
echo "Creating configuration..."
cat > qna_config.json << EOL
{
  "intentName": "QnAIntent",
  "description": "Q&A via Knowledge Base",
  "parentIntentSignature": "AMAZON.QnAIntent",
  "qnAIntentConfiguration": {
    "dataSourceConfiguration": {
      "bedrockKnowledgeStoreConfiguration": {
        "bedrockKnowledgeBaseArn": "$KNOWLEDGE_BASE_ARN"
      }
    },
    "bedrockModelConfiguration": {
      "modelArn": "arn:aws:bedrock:$REGION::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
    }
  }
}
EOL

# Delete the existing QnAIntent (if it exists)
echo "Deleting existing QnAIntent..."
aws lexv2-models delete-intent \
  --bot-id "$BOT_ID" \
  --bot-version "$BOT_VERSION" \
  --locale-id "$LOCALE_ID" \
  --intent-id "4L9UIT0PFW" || echo "No existing intent to delete"

# Create the updated QnAIntent
echo "Creating QnAIntent..."
aws lexv2-models create-intent \
  --bot-id "$BOT_ID" \
  --bot-version "$BOT_VERSION" \
  --locale-id "$LOCALE_ID" \
  --cli-input-json file://qna_config.json || exit 1

# Rebuild the bot locale
echo "Rebuilding bot locale..."
aws lexv2-models build-bot-locale \
  --bot-id "$BOT_ID" \
  --bot-version "$BOT_VERSION" \
  --locale-id "$LOCALE_ID" || exit 1

echo "QnAIntent added successfully!"