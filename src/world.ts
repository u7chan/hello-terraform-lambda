import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';

export default async (
  _event: APIGatewayEvent,
  _context: Context
): Promise<APIGatewayProxyResult> => {
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'world 🗺',
    }),
  };
};
