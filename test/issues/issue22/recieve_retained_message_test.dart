import 'dart:async';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:test/test.dart';

Future<int> main() async {
  recieveRetainedMessageTest(String broker_url, int port, bool useWs, int retainDelay) async {
    final client = MqttServerClient(broker_url, "");
    client.useWebSocket = useWs;
    client.port = port;

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

    recvData = await recieveRetained().timeout(Duration(seconds: 60), onTimeout: () => print("Broker timeout, nothing was recieved!"));

    expect(recvData, sendData);

    client.unsubscribeStringTopic(topic);
    client.disconnect();
  }
 
  //WS
  test("[broker.emqx.io] websocket right after its published", () => recieveRetainedMessageTest("ws://broker.emqx.io/mqtt", 8083, true, 0));

  test("[broker.emqx.io] websocket after a delay", () => recieveRetainedMessageTest("ws://broker.emqx.io/mqtt", 8083, true, 1));

  test("[broker.hivemq.com] websocket right after its published", () => recieveRetainedMessageTest("ws://broker.hivemq.com/mqtt", 8000, true, 0));

  test("[broker.hivemq.com] websocket after a delay", () => recieveRetainedMessageTest("ws://broker.hivemq.com/mqtt", 8000, true, 1));

  //TCP

  test("[broker.emqx.io] tcp right after its published", () => recieveRetainedMessageTest("broker.emqx.io", 1883, false, 0));

  test("[broker.emqx.io] tcp after a delay", () => recieveRetainedMessageTest("broker.emqx.io", 1883, false, 1));

  test("[broker.hivemq.com] tcp right after its published", () => recieveRetainedMessageTest("broker.hivemq.com", 1883, false, 0));

  test("[broker.hivemq.com] tcp after a delay", () => recieveRetainedMessageTest("broker.hivemq.com", 1883, false, 1));


  return 0;
}