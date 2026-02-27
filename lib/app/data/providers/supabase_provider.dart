import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static SupabaseQueryBuilder from(String table) => client.from(table);

  static RealtimeChannel channel(String name) => client.channel(name);

  static Future<void> removeChannel(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }

  static Future<T> rpc<T>(String fn, {Map<String, dynamic>? params}) async {
    final response = await client.rpc(fn, params: params ?? {});
    return response as T;
  }

  static FunctionsClient get functions => client.functions;
}
