package com.cybertrist.smartbudget

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.provider.OpenableColumns
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
    private val canalFichiers = "smartbudget/fichiers"
    private val canalBanque = "smartbudget/banque"

    /** Le canal de la banque, gardé pour lui passer le lien de retour. */
    private var canalBanqueOuvert: MethodChannel? = null

    /**
     * Le lien de retour de la banque, smartbudget://banque?code=…, en
     * attente que le Dart le lise : il peut arriver avant que l'application
     * soit déverrouillée, ou avant que le moteur ait démarré.
     */
    private var lienEnAttente: String? = null

    /** Le nom du dernier fichier choisi, tel que le sélecteur le montre. */
    private var nomChoisi: String? = null

    /**
     * Les sauvegardes passent par le sélecteur du système : il laisse choisir
     * un emplacement, Téléchargements, un dossier synchronisé, sans que
     * l'application demande le droit de lire tout le stockage. Une seule
     * demande à la fois, dont on garde la réponse en attente. Repris de
     * BodyCount.
     */
    private var attenteOuverture: MethodChannel.Result? = null
    private var attenteEnregistrement: MethodChannel.Result? = null
    private var aEnregistrer: File? = null

    private val choisirFichier =
        registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            val reponse = attenteOuverture ?: return@registerForActivityResult
            attenteOuverture = null
            if (uri == null) {
                reponse.success(null)
                return@registerForActivityResult
            }
            // Recopié dans le cache privé : le Dart lit un chemin, et l'accès
            // à l'URI ne survit pas forcément à l'activité.
            nomChoisi = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0) else null
            }
            Thread {
                val copie = File(cacheDir, "restauration.sbx")
                val ok = copier(uri, copie, versUri = false)
                runOnUiThread { reponse.success(if (ok) copie.path else null) }
            }.start()
        }

    private val creerFichier =
        registerForActivityResult(
            ActivityResultContracts.CreateDocument("application/octet-stream"),
        ) { uri ->
            val reponse = attenteEnregistrement ?: return@registerForActivityResult
            val source = aEnregistrer
            attenteEnregistrement = null
            aEnregistrer = null
            if (uri == null || source == null) {
                reponse.success(false)
                return@registerForActivityResult
            }
            Thread {
                val ok = copier(uri, source, versUri = true)
                runOnUiThread { reponse.success(ok) }
            }.start()
        }

    private fun copier(uri: Uri, fichier: File, versUri: Boolean): Boolean {
        return try {
            if (versUri) {
                contentResolver.openOutputStream(uri, "w")?.use { sortie ->
                    fichier.inputStream().use { it.copyTo(sortie, 1 shl 20) }
                } ?: return false
            } else {
                contentResolver.openInputStream(uri)?.use { entree ->
                    fichier.outputStream().use { entree.copyTo(it, 1 shl 20) }
                } ?: return false
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val debogable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debogable) window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
        retenirLien(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        retenirLien(intent)
        lienEnAttente?.let { canalBanqueOuvert?.invokeMethod("lien", it) }
    }

    private fun retenirLien(intent: Intent?) {
        val lien = intent?.data ?: return
        if (lien.scheme == "smartbudget") lienEnAttente = lien.toString()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalEcran)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "protegerEcran" -> {
                        val actif = call.argument<Boolean>("actif") ?: true
                        val debogable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
                        if (actif && !debogable) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(actif)
                    }
                    else -> result.notImplemented()
                }
            }

        canalBanqueOuvert = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalBanque).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "ouvrirLien" -> {
                        val url = call.argument<String>("url")
                        if (url == null) {
                            result.error("url", "Adresse absente", null)
                        } else {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            result.success(true)
                        }
                    }
                    "lienEnAttente" -> {
                        result.success(lienEnAttente)
                        lienEnAttente = null
                    }
                    "nomChoisi" -> result.success(nomChoisi)
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canalFichiers)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ouvrir" -> {
                        if (attenteOuverture != null) {
                            result.error("occupe", "Une sélection est déjà ouverte", null)
                        } else {
                            attenteOuverture = result
                            choisirFichier.launch(arrayOf("*/*"))
                        }
                    }
                    "enregistrer" -> {
                        val chemin = call.argument<String>("chemin")
                        val nom = call.argument<String>("nom") ?: "smartbudget.sbx"
                        if (chemin == null || attenteEnregistrement != null) {
                            result.error("occupe", "Enregistrement impossible", null)
                        } else {
                            attenteEnregistrement = result
                            aEnregistrer = File(chemin)
                            creerFichier.launch(nom)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
