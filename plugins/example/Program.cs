using System;
using System.Text;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;

namespace Example
{
    class Program
    {
        static EventHubProducerClient producerClient;  
        static async Task Main(string[] args)
        {

            var connectionString = GetEnvVarOrExit("CONNECTION_STRING");
            var eventHubName = GetEnvVarOrExit("EVENTHUB");

            // number of events to be sent to the event hub
            var numOfEvents = 1;

            // Create a producer client that you can use to send events to an event hub
            producerClient = new EventHubProducerClient(connectionString, eventHubName);

            // Create a batch of events 
            using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

            var mce = File.ReadAllBytes("mce.json");

            eventBatch.TryAdd(new EventData(mce));         
            producerClient.SendAsync(eventBatch).GetAwaiter().GetResult();   
            Console.WriteLine("MCE Published");             
        }

        private static string GetEnvVarOrExit(string variableName){

            var value = Environment.GetEnvironmentVariable(variableName);

            if(String.IsNullOrEmpty(value)){
                Console.WriteLine($"Please set the environment variable: {variableName}");        
                Environment.Exit(1);
            }

            return value;
        }
    }
}
