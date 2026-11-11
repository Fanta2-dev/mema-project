package com.example.mema.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebAuthConfig implements WebMvcConfigurer {

    private final AuthInterceptor authInterceptor;

    public WebAuthConfig(AuthInterceptor authInterceptor) {
        this.authInterceptor = authInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor).addPathPatterns(
                "/stocks", "/stocks/**",
                "/medicaments", "/medicaments/**",
                "/pharmacies", "/pharmacies/**",
                "/periodes-garde", "/periodes-garde/**",
                "/alertes", "/alertes/**",
                "/utilisateurs", "/utilisateurs/**",
                "/demandes-medicaments", "/demandes-medicaments/**",
                "/inscriptions", "/inscriptions/**",
                "/admin", "/admin/**"
        );
    }
}