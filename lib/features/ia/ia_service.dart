import '../../core/models/ia.dart';
import '../../core/network/api_client.dart';

/// CU29 (recomendador) + CU30 (chatbot).
class IaService {
  final ApiClient _api;

  IaService(this._api);

  Future<List<ProductoRecomendado>> recomendaciones() async {
    final data = await _api.get('/ia/recomendaciones') as Map<String, dynamic>;
    return (data['items'] as List<dynamic>)
        .map((e) => ProductoRecomendado.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRespuesta> chat(String mensaje, List<MensajeChat> historial) async {
    final data = await _api.post(
      '/ia/chat',
      body: {
        'mensaje': mensaje,
        'historial': historial.map((h) => h.toJson()).toList(),
      },
    );
    return ChatRespuesta.fromJson(data as Map<String, dynamic>);
  }
}
