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
  /// Public HiveMQ has no auth and is not safe for health chat.
  /// Primary messaging uses Firestore; keep connect as a no-op until a private broker exists.
  static const bool mqttEnabled = false;

  Future<void> connect() async {
    if (!mqttEnabled) {
      return;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    try {
      _client.setProtocolV311();
      _client.logging(on: false);
      _client.keepAlivePeriod = 60 * 5;
      _client.autoReconnect = true;

      await _client.connect();

      _client.subscribe(
          '$MQTT_UNIQUE_TOPIC_NAME/chats/$uid', MqttQos.atLeastOnce);

      _client.updates?.listen(_onMessageReceived);
    } catch (e) {
      print('MQTT connect failed: $e');
    }
  }

  Future<void> disconnect() async {
    return _client.disconnect();
  }
}
