import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';
import {
  DynamoDBClient,
  WriteRequest,
  BatchWriteItemCommand,
} from '@aws-sdk/client-dynamodb';

const client = new DynamoDBClient({ region: 'ap-northeast-3' });
const tableName = 'terrform-table';

export default async (
  _event: APIGatewayEvent,
  _context: Context
): Promise<APIGatewayProxyResult> => {
  const writeRequests: WriteRequest[] = [
    {
      PutRequest: {
        Item: {
          email: { S: `${new Date().toISOString()}@example.com` },
          name: { S: `${(Math.random() + 1).toString(36).substring(7)}` },
          role: { S: Math.random() < 0.5 ? 'admin' : 'operator' },
          delete: { BOOL: true },
        },
      },
    },
  ];

  await client.send(
    new BatchWriteItemCommand({
      RequestItems: {
        [tableName]: writeRequests,
      },
    })
  );

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'OK',
    }),
  };
};
