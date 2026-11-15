package com.example.pulsso

import io.flutter.embedding.android.FlutterFragmentActivity

// Stripe necesita FlutterFragmentActivity (en lugar de FlutterActivity)
// para mostrar sus pantallas nativas de tarjeta.
class MainActivity : FlutterFragmentActivity()
