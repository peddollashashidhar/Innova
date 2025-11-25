package com.cloudnative.demo;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping
public class HelloController {

    @GetMapping("/hello")
    public ResponseEntity<String> hello() {
        return ResponseEntity.ok("Hello from DemoApplication");
    }

    @GetMapping("/")
    public ResponseEntity<String> root() {
        // Small convenience mapping so the application root doesn't return a 404 (Whitelabel)
        return ResponseEntity.ok("Hello from DemoApplication (root). Try /hello for the API endpoint.");
    }
}
