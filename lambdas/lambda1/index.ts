export const handler = async (event: any = {}): Promise<any> => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: "Hello from lambda1" }),
  };
};
