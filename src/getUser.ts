import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';
import {
  DynamoDBClient,
  ScanCommand,
  ScanCommandInput,
} from '@aws-sdk/client-dynamodb';

const client = new DynamoDBClient({ region: 'ap-northeast-3' });
const tableName = 'terrform-table';

export const getUser = async (
  _event: APIGatewayEvent,
  _context: Context
): Promise<APIGatewayProxyResult> => {
  const params: ScanCommandInput = {
    TableName: tableName,
  };

  const result = await client.send(new ScanCommand(params));

  return {
    statusCode: 200,
    body: JSON.stringify({
      results: result.Items,
    }),
  };
};
