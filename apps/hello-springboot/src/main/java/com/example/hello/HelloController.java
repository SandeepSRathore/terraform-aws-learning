package com.example.hello;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Tells you WHICH server answered and WHICH build it runs, so after a
 * redeploy you can see the new version is live.
 */
@RestController
class HelloController {

	private final String message;

	private final String version;

	HelloController(@Value("${app.message}") String message, @Value("${app.version}") String version) {
		this.message = message;
		this.version = version;
	}

	@GetMapping("/")
	Map<String, String> hello() {
		return Map.of(
				"message", this.message,
				"version", this.version,
				"host", hostname(),
				"java", System.getProperty("java.version"));
	}

	private static String hostname() {
		try {
			return InetAddress.getLocalHost().getHostName();
		}
		catch (UnknownHostException ex) {
			return "unknown";
		}
	}

}
