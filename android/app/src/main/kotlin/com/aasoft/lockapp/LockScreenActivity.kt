package com.aasoft.lockapp

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class LockScreenActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Main Container with Gradient Background
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
            setBackground(GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor("#0F172A"), Color.parseColor("#1E293B"))
            ))
        }

        // Icon/Emoji Container
        val iconText = TextView(this).apply {
            text = "⏳"
            textSize = 64f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        // Title
        val title = TextView(this).apply {
            text = "Günlük Sınır Doldu!"
            textSize = 28f
            setTextColor(Color.WHITE)
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        // Subtitle
        val subtitle = TextView(this).apply {
            text = "Bugünkü sosyal medya sürenizi tamamladınız.\nDevam etmek için LockApp'e dönüp 5 dakika kazanmalısınız."
            textSize = 16f
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.2f)
            setPadding(0, 0, 0, 80)
        }

        // Styled Button
        val btnHome = Button(this).apply {
            text = "Jeton Kazan ve Süre Al"
            setTextColor(Color.WHITE)
            textSize = 16f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(64, 32, 64, 32)
            
            // Rounded Gradient Background for Button
            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#3B82F6"))
                cornerRadius = 24f
            }
            setBackground(btnBg)
            
            setOnClickListener {
                val intent = Intent(this@LockScreenActivity, MainActivity::class.java)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                startActivity(intent)
                finish()
            }
        }

        mainLayout.addView(iconText)
        mainLayout.addView(title)
        mainLayout.addView(subtitle)
        mainLayout.addView(btnHome)

        setContentView(mainLayout)
    }

    override fun onBackPressed() {
        // Prevent bypassing the lock
        val startMain = Intent(Intent.ACTION_MAIN)
        startMain.addCategory(Intent.CATEGORY_HOME)
        startMain.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(startMain)
        finish()
    }
}
