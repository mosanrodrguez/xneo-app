package com.xneo.app.ui.login

import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.xneo.app.R
import com.xneo.app.MainActivity
import com.xneo.app.network.RetrofitClient
import com.xneo.app.network.SessionManager
import com.xneo.app.model.LoginRequest
import com.xneo.app.model.RegisterRequest
import kotlinx.coroutines.*

class LoginActivity : AppCompatActivity() {
    
    private lateinit var sessionManager: SessionManager
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)
        
        sessionManager = SessionManager(this)
        
        findViewById<android.widget.Button>(R.id.btn_login).setOnClickListener { login() }
        findViewById<android.widget.Button>(R.id.btn_register).setOnClickListener { register() }
        
        findViewById<android.widget.TextView>(R.id.tab_login).setOnClickListener {
            findViewById<android.widget.LinearLayout>(R.id.login_form).visibility = View.VISIBLE
            findViewById<android.widget.LinearLayout>(R.id.register_form).visibility = View.GONE
        }
        
        findViewById<android.widget.TextView>(R.id.tab_register).setOnClickListener {
            findViewById<android.widget.LinearLayout>(R.id.login_form).visibility = View.GONE
            findViewById<android.widget.LinearLayout>(R.id.register_form).visibility = View.VISIBLE
        }
    }
    
    private fun login() {
        val username = findViewById<android.widget.EditText>(R.id.et_login_user).text.toString().trim()
        val password = findViewById<android.widget.EditText>(R.id.et_login_pass).text.toString()
        
        if (username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Completa todos los campos", Toast.LENGTH_SHORT).show()
            return
        }
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response = RetrofitClient.api.login(LoginRequest(username, password))
                if (response.isSuccessful) {
                    val auth = response.body()
                    auth?.let {
                        sessionManager.token = "Bearer ${it.token}"
                        sessionManager.username = it.user.username
                        withContext(Dispatchers.Main) {
                            startActivity(android.content.Intent(this@LoginActivity, MainActivity::class.java))
                            finish()
                        }
                    }
                } else {
                    withContext(Dispatchers.Main) {
                        Toast.makeText(this@LoginActivity, "Credenciales incorrectas", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@LoginActivity, "Error de conexión", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
    
    private fun register() {
        val username = findViewById<android.widget.EditText>(R.id.et_reg_user).text.toString().trim()
        val password = findViewById<android.widget.EditText>(R.id.et_reg_pass).text.toString()
        val confirm = findViewById<android.widget.EditText>(R.id.et_reg_confirm).text.toString()
        
        if (username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Completa todos los campos", Toast.LENGTH_SHORT).show()
            return
        }
        if (password != confirm) {
            Toast.makeText(this, "Las contraseñas no coinciden", Toast.LENGTH_SHORT).show()
            return
        }
        
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val response = RetrofitClient.api.register(RegisterRequest(username, password))
                if (response.isSuccessful) {
                    val auth = response.body()
                    auth?.let {
                        sessionManager.token = "Bearer ${it.token}"
                        sessionManager.username = it.user.username
                        withContext(Dispatchers.Main) {
                            Toast.makeText(this@LoginActivity, "Cuenta creada", Toast.LENGTH_SHORT).show()
                            startActivity(android.content.Intent(this@LoginActivity, MainActivity::class.java))
                            finish()
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@LoginActivity, "Error de conexión", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
}
