// ignore_for_file: constant_identifier_names


import 'package:firebase_auth/firebase_auth.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';



import 'mqtt_listener.dart';

class MQTTService {
  MQTTService._();
  static final MQTTService instance = MQTTService._();
  final _client = MqttServerClient.withPort("broker.hivemq.com", "", 1883);
  //region MQTT port and unique name

  MqttServerClient get client => _client;
  static const MQTT_UNIQUE_TOPIC_NAME =
      'yarisahealthcare'; // Don't add underscore at the end of the name

  static const mMQTT_UNIQUE_TOPIC_NAME = '${MQTT_UNIQUE_TOPIC_NAME}_';

  final Set<MQTTMessageListener> _listeners = {};

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage?>>? msg) {
    if (msg != null && msg.isNotEmpty) {
      final recMess = msg[0].payload as MqttPublishMessage;

      final payloadAsString =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // final data = jsonDecode(payloadAsString);
      // if (data['data_type'] == "delivery-request") {
      //   log(data["data"].toString());
      //   final ride = RideOrder.fromMap(data['data']);

      //   showAlertModal(order: ride);
      // }

      for (var i = 0; i < _listeners.length; i++) {
        _listeners.elementAt(i).onMessageReceived(payloadAsString);
      }
    }
  }

  void registerListener(MQTTMessageListener listener) {
    _listeners.add(listener);
  }

  void unregisterListener(MQTTMessageListener listener) {
    _listeners.remove(listener);
  }

  ///
  /// Makes a connection to the MQTT broker and subscribes to ride request
  /// topic
  ///
  Future<void> connect() async {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    _client.setProtocolV311();
    _client.logging(on: true);
    _client.keepAlivePeriod = 60 * 5;
    _client.autoReconnect = true;

    await _client.connect();

    // _client.subscribe(
    //     "${mMQTT_UNIQUE_TOPIC_NAME}delivery_request_${FirebaseAuth.instance.currentUser?.uid}",
    //     MqttQos.atLeastOnce);
    // _client.subscribe(
    //     '$MQTT_UNIQUE_TOPIC_NAME/new_ride_request/${FirebaseAuth.instance.currentUser?.uid}',
    //     MqttQos.atLeastOnce);
    // _client.subscribe(
    //     '$MQTT_UNIQUE_TOPIC_NAME/ride_request_status/${FirebaseAuth.instance.currentUser?.uid}',
    //     MqttQos.atLeastOnce);
    _client.subscribe(
        '$MQTT_UNIQUE_TOPIC_NAME/chats/${FirebaseAuth.instance.currentUser?.uid}',
        MqttQos.atLeastOnce);

    _client.updates?.listen(_onMessageReceived);

    return;
  }

  Future<void> disconnect() async {
    return _client.disconnect();
  }
}
