import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:test/test.dart';

Future<int> main() async {
  recieveRetainedMessageTest(String broker_url, int retainDelay) async {
    final client = MqttServerClient(broker_url, "");
    
    String topic = "iWantToBeRetained";
    var sendData = Uint8Buffer();
    sendData.add(255); //Super unique data
    Uint8Buffer? recvData;

    await client.connect();
    print("Publishing Message: $sendData at $topic");
    client.publishMessage(topic, MqttQos.exactlyOnce, sendData, retain: true);
    
    print("Waiting for $retainDelay seconds before subscribing");
    await MqttUtilities.asyncSleep(retainDelay);

    client.subscribe(topic, MqttQos.exactlyOnce);
    
    Future recieveRetained() {
      var completer = Completer();
      client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final data = (c[0].payload as MqttPublishMessage).payload.message!;
        print("Recieved Message: ${data} at ${c[0].topic}");
        if (c[0].topic == topic) {
          completer.complete(data);
        }
      });
      return completer.future;
    }

    recvData = await recieveRetained().timeout(Duration(seconds: 5), onTimeout: () => print("Broker timeout, nothing was recieved!"));

    expect(recvData, sendData);

    client.unsubscribeStringTopic(topic);
    client.disconnect();
  }

  test("[test.mosquitto.org] right after its published", () => recieveRetainedMessageTest("test.mosquitto.org", 0));

  test("[test.mosquitto.org] after a delay", () => recieveRetainedMessageTest("test.mosquitto.org", 1));

  test("[broker.hivemq.com] right after its published", () => recieveRetainedMessageTest("broker.hivemq.com", 0));

  test("[broker.hivemq.com] after a delay", () => recieveRetainedMessageTest("broker.hivemq.com", 1));

  return 0;
}
