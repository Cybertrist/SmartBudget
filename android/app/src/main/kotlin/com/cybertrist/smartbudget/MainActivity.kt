package com.cybertrist.smartbudget

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity et non FlutterActivity : la demande d'empreinte
 * d'Android s'affiche dans un fragment, et refuse de s'ouvrir sans.
 *
 * FLAG_SECURE est posé dès la création de la fenêtre, avant que le moteur
 * Flutter ne dessine quoi que ce soit : des soldes et des libellés de
 * paiement n'ont rien à faire dans une capture d'écran ni dans l'aperçu
 * du multitâche. Le canal ne sert qu'à le retirer, si le réglage le dit.
 *
 * Seule exception : la version de débogage, celle de l'émulateur. Là, il
 * faut pouvoir capturer l'écran pour le vérifier, et les données sont
 * fictives. L'APK publié, lui, n'est jamais débogable.
 */
class MainActivity : FlutterFragmentActivity() {

    private val canalEcran = "smartbudget/ecran"

    override fun onCreate(savedInstanceState: Bundle?) {
        val debogable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debogable) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalEcran)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "protegerEcran" -> {
                        val actif = call.argument<Boolean>("actif") ?: true
                        if (actif) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(actif)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
