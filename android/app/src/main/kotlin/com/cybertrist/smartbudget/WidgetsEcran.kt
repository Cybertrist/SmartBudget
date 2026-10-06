package com.cybertrist.smartbudget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Un widget de l'écran d'accueil : une image dessinée par l'application,
 * avec les mêmes composants que ses écrans (lib/ecran_accueil). Un appui
 * ouvre l'application à [page], une fois le verrou passé.
 *
 * La clé [cle], partagée avec le Dart, donne le chemin de l'image. Un
 * widget sans chiffres montre toujours la même, [fixe], rangée dans les
 * ressources.
 */
abstract class WidgetImage(
    private val cle: String,
    private val page: String,
    private val fixe: Int = 0,
) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val image =
            if (fixe != 0) null
            else widgetData.getString(cle, null)?.let { runCatching { BitmapFactory.decodeFile(it) }.getOrNull() }
        // Un schéma à part : « smartbudget:// » est le retour de la banque.
        val lien =
            Uri.parse("sbwidget://ouvrir")
                .buildUpon()
                .appendQueryParameter("chemin", page)
                .appendQueryParameter("widget", cle)
                .build()
        for (id in appWidgetIds) {
            val vues = RemoteViews(context.packageName, R.layout.widget_image)
            if (fixe != 0) vues.setImageViewResource(R.id.widget_image, fixe)
            if (image != null) vues.setImageViewBitmap(R.id.widget_image, image)
            // Pas encore d'image : l'application n'a pas été ouverte depuis
            // la pose du widget.
            val pret = fixe != 0 || image != null
            vues.setViewVisibility(R.id.widget_image, if (pret) View.VISIBLE else View.GONE)
            vues.setViewVisibility(R.id.widget_attente, if (pret) View.GONE else View.VISIBLE)
            vues.setOnClickPendingIntent(
                R.id.widget_racine,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, lien),
            )
            appWidgetManager.updateAppWidget(id, vues)
        }
    }
}

class WidgetBudget : WidgetImage("budget", "/mois")

class WidgetEpargne : WidgetImage("epargne", "/epargne")

class WidgetComptes : WidgetImage("comptes", "/mois")

class WidgetAnalyse : WidgetImage("analyse", "/analyse")

class WidgetDepenses : WidgetImage("depenses", "/analyse")

class WidgetAVenir : WidgetImage("avenir", "/analyse")

class WidgetEspeces : WidgetImage("especes", "/especes/nouvelle", R.drawable.widget_apercu_especes)
