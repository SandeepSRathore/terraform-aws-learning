package com.example.hello;

import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = "app.message=hi from a test")
class HelloControllerTests {

	@Autowired
	private MockMvc mvc;

	@Test
	void helloReturnsConfiguredMessage() throws Exception {
		this.mvc.perform(get("/"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.message").value("hi from a test"))
			.andExpect(jsonPath("$.version").value("0.0.1-SNAPSHOT"));
	}

	@Test
	void healthIsUp() throws Exception {
		this.mvc.perform(get("/actuator/health"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.status").value("UP"));
	}

}
