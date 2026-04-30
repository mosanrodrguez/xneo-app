package com.xneo.app

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.xneo.app.ui.home.HomeFragment
import com.xneo.app.ui.upload.UploadFragment
import com.xneo.app.ui.downloads.DownloadsFragment
import com.xneo.app.ui.profile.ProfileFragment
import com.xneo.app.ui.login.LoginActivity
import com.xneo.app.network.SessionManager

class MainActivity : AppCompatActivity() {
    
    private lateinit var sessionManager: SessionManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        sessionManager = SessionManager(this)
        
        if (!sessionManager.isLoggedIn()) {
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
            return
        }
        
        setContentView(R.layout.activity_main)
        
        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_nav)
        
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, HomeFragment())
            .commit()
        
        bottomNav.setOnItemSelectedListener { item ->
            val fragment: Fragment = when (item.itemId) {
                R.id.nav_home -> HomeFragment()
                R.id.nav_upload -> UploadFragment()
                R.id.nav_downloads -> DownloadsFragment()
                R.id.nav_profile -> ProfileFragment()
                else -> HomeFragment()
            }
            supportFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit()
            true
        }
    }
}
