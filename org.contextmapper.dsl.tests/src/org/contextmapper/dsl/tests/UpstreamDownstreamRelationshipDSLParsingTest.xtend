/*
 * Copyright 2018 The Context Mapper Project Team
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.contextmapper.dsl.tests

import com.google.inject.Inject
import org.contextmapper.dsl.contextMappingDSL.ContextMappingDSLPackage
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel
import org.contextmapper.dsl.contextMappingDSL.CustomerSupplierRelationship
import org.contextmapper.dsl.contextMappingDSL.DownstreamRole
import org.contextmapper.dsl.contextMappingDSL.Relationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship
import org.contextmapper.dsl.contextMappingDSL.UpstreamRole
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.contextmapper.dsl.tests.util.ParsingErrorAssertions.*
import static org.contextmapper.dsl.validation.ValidationMessages.*
import static org.junit.jupiter.api.Assertions.*
import java.util.ArrayList
import org.contextmapper.dsl.contextMappingDSL.DownstreamGovernanceRights

@ExtendWith(InjectionExtension)
@InjectWith(ContextMappingDSLInjectorProvider)
class UpstreamDownstreamRelationshipDSLParsingTest {
	@Inject
	ParseHelper<ContextMappingModel> parseHelper

	ValidationTestHelper validationTestHelper = new ValidationTestHelper();

	@Test
	def void canDefineUpstreamDownstream() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				testContext [OHS,PL]Upstream-Downstream[CF] anotherTestContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);

		val Relationship relationship = result.map.relationships.get(0)
		assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))

		val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
		assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
		assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)

		assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE))
		assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))

		assertTrue(upstreamDownstreamRelationship.downstreamRoles.contains(DownstreamRole.CONFORMIST))	
	}
	
	@Test
	def void canDefineDownstreamUpstream() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [CF]Downstream-Upstream[OHS,PL] testContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);

		val Relationship relationship = result.map.relationships.get(0)
		assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))

		val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
		assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
		assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)

		assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE))
		assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))

		assertTrue(upstreamDownstreamRelationship.downstreamRoles.contains(DownstreamRole.CONFORMIST))
	}

	@Test
	def void canDefineUpstreamDownstreamInShortSyntaxFlowFromLeftToRight() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				<<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [U,OHS,PL]->[D,CF] anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [U,OHS,PL]->[CF] anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [OHS,PL]->[D,CF] anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [OHS,PL]->[CF] anotherTestContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))
	
			val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
			assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
			assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)
	
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE))
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))
	
			assertTrue(upstreamDownstreamRelationship.downstreamRoles.contains(DownstreamRole.CONFORMIST))			
		}
	}

	@Test
	def void canDefineUpstreamDownstreamInShortSyntaxFlowFromRightToLeft() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				<<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D,CF]<-[U,OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D,CF]<-[OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [CF]<-[U,OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [CF]<-[OHS,PL] testContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))
	
			val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
			assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
			assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)
	
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE))
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))
	
			assertTrue(upstreamDownstreamRelationship.downstreamRoles.contains(DownstreamRole.CONFORMIST))			
		}
	}
	
	@Test
	def void canDefineUpstreamDownstreamInShortSyntaxWithUpstreamRolesOnly() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				<<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D]<-[U,OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D]<-[OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext <-[U,OHS,PL] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext <-[OHS,PL] testContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))
	
			val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
			assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
			assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)
	
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.OPEN_HOST_SERVICE))
			assertTrue(upstreamDownstreamRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))
		}
	}
	
	@Test
	def void canDefineUpstreamDownstreamInShortSyntaxWithDownstreamRolesOnly() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				<<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D,CF]<-[U] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D,CF]<- testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [CF]<-[U] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [CF]<- testContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))
	
			val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
			assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
			assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)
	
			assertTrue(upstreamDownstreamRelationship.downstreamRoles.contains(DownstreamRole.CONFORMIST))			
		}
	}

	@Test
	def void canDefineCustomerSupplier() {
		// given
		val String dslSnippet = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 anotherTestContext Customer-Supplier testContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);

		val Relationship relationship = result.map.relationships.get(0)
		assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))

		val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
		assertEquals("testContext", customerSupplierRelationship.upstream.name)
		assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)
	}
	
	@Test
	def void canDefineSupplierCustomer() {
		// given
		val String dslSnippet = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 testContext Supplier-Customer anotherTestContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);

		val Relationship relationship = result.map.relationships.get(0)
		assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))

		val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
		assertEquals("testContext", customerSupplierRelationship.upstream.name)
		assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)
	}
	
	@Test
	def void canDefineSupplierCustomerWithRoles() {
		// given
		val String dslSnippet = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 testContext [PL]Supplier-Customer[ACL] anotherTestContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);

		val Relationship relationship = result.map.relationships.get(0)
		assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))

		val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
		assertEquals("testContext", customerSupplierRelationship.upstream.name)
		assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)
		
		assertTrue(customerSupplierRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))
		assertTrue(customerSupplierRelationship.downstreamRoles.contains(DownstreamRole.ANTICORRUPTION_LAYER))
	}

	@Test
	def void canDefineCustomerSupplierInShortSyntaxFlowFromRightToLeft() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 <<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		// all variants only with S and C
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [C]<-[S] testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext [D,C]<-[U,S] testContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))
	
			val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
			assertEquals("testContext", customerSupplierRelationship.upstream.name)
			assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)			
		}
	}

	@Test
	def void canDefineCustomerSupplierInShortSyntaxFlowFromLeftToRight() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 <<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		// all variants only with S and C
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [S]->[C] anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [U,S]->[D,C] anotherTestContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))
	
			val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
			assertEquals("testContext", customerSupplierRelationship.upstream.name)
			assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)			
		}
	}

	@Test
	def void canDefineCustomerSupplierInShortSyntaxWithRoles() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 <<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		// all variants only with S and C
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [S,PL]->[C,ACL] anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext [U,S,PL]->[D,C,ACL] anotherTestContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(CustomerSupplierRelationship))
	
			val CustomerSupplierRelationship customerSupplierRelationship = relationship as CustomerSupplierRelationship
			assertEquals("testContext", customerSupplierRelationship.upstream.name)
			assertEquals("anotherTestContext", customerSupplierRelationship.downstream.name)	
			
			assertTrue(customerSupplierRelationship.upstreamRoles.contains(UpstreamRole.PUBLISHED_LANGUAGE))
			assertTrue(customerSupplierRelationship.downstreamRoles.contains(DownstreamRole.ANTICORRUPTION_LAYER))		
		}
	}

	@Test
	def void throwValidationErrorIfCustomerSupplierImplementsOHS() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext Customer-Supplier[OHS] testContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		validationTestHelper.assertError(result, ContextMappingDSLPackage.Literals.UPSTREAM_DOWNSTREAM_RELATIONSHIP, "",
			CUSTOMER_SUPPLIER_WITH_OHS_ERROR_MESSAGE);
	}

	@Test
	def void throwValidationErrorIfCustomerSupplierImplementsACL() {
		// given
		val String dslSnippet = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 anotherTestContext [ACL]Customer-Supplier testContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		validationTestHelper.assertWarning(result, ContextMappingDSLPackage.Literals.UPSTREAM_DOWNSTREAM_RELATIONSHIP,
			"", CUSTOMER_SUPPLIER_WITH_ACL_WARNING_MESSAGE);
	}

	@Test
	def void throwValidationErrorIfCustomerSupplierImplementsConformist() {
		// given
		val String dslSnippet = '''
			ContextMap {
				 contains testContext
				 contains anotherTestContext
			
				 anotherTestContext [CF]Customer-Supplier testContext
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		validationTestHelper.assertError(result, ContextMappingDSLPackage.Literals.UPSTREAM_DOWNSTREAM_RELATIONSHIP, "",
			CUSTOMER_SUPPLIER_WITH_CONFORMIST_ERROR_MESSAGE);
	}

	@Test
	def void expectRelationshipContextsBePartOfMap() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				 contains anotherTestContext
			
				 <<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		val dslSnippets = new ArrayList<String>;
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext Customer-Supplier testContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext Customer-Supplier anotherTestContext"));
		
		for(dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			validationTestHelper.assertError(result, ContextMappingDSLPackage.Literals.CUSTOMER_SUPPLIER_RELATIONSHIP, "",
				String.format(RELATIONSHIP_CONTEXT_NOT_ON_MAP_ERROR_MESSAGE, "testContext"));			
		}
	}

	@Test
	def void canGiveUpstreamDownstreamRelationshipName() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [U]->[D] testContext : myRelName
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
		assertEquals("myRelName", result.map.relationships.get(0).name);
	}

	@Test
	def void canGiveCustomerSupplierRelationshipName() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [S]->[C] testContext : myRelName
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
		assertEquals("myRelName", result.map.relationships.get(0).name);
	}

	@Test
	def void canDefineTechnology() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [S]->[C] testContext {
					implementationTechnology = "RESTful HTTP"
				}
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
		assertEquals("RESTful HTTP", result.map.relationships.get(0).implementationTechnology);
	}

	@Test
	def void canParseAttributesInAnyOrder1() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [S]->[C] testContext {
					implementationTechnology = "RESTful HTTP"
					downstreamRights = INFLUENCER
				}
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
	}
	
	@Test
	def void canParseAttributesInAnyOrder2() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [S]->[C] testContext {
					downstreamRights = INFLUENCER
					implementationTechnology = "RESTful HTTP"
				}
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
	}

	@Test
	def void canDefineUpstreamDownstreamRelationshipWithoutBrackets() {
		// given
		val String dslSnippetTemplate = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				<<relationship>>
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext
		''';
		
		val dslSnippets = new ArrayList<String>;
		// all variants only with S and C
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "testContext -> anotherTestContext"));
		dslSnippets.add(dslSnippetTemplate.replace("<<relationship>>", "anotherTestContext <- testContext"));
		
		for(String dslSnippet : dslSnippets) {
			// when
			val ContextMappingModel result = parseHelper.parse(dslSnippet);
			// then
			assertThatNoParsingErrorsOccurred(result);
			assertThatNoValidationErrorsOccurred(result);
	
			val Relationship relationship = result.map.relationships.get(0)
			assertTrue(relationship.class.interfaces.contains(UpstreamDownstreamRelationship))
	
			val UpstreamDownstreamRelationship upstreamDownstreamRelationship = relationship as UpstreamDownstreamRelationship
			assertEquals("testContext", upstreamDownstreamRelationship.upstream.name)
			assertEquals("anotherTestContext", upstreamDownstreamRelationship.downstream.name)	
		}
	}
	
	@Test
	def void canDefineAttributesWithoutEqualSign() {
		// given
		val String dslSnippet = '''
			ContextMap {
				contains testContext
				contains anotherTestContext
			
				anotherTestContext [S]->[C] testContext {
					implementationTechnology "RESTful HTTP"
					downstreamRights INFLUENCER
					exposedAggregates agg1
				}
			}
			
			BoundedContext testContext
			BoundedContext anotherTestContext {
				Aggregate agg1
			}
		''';
		// when
		val ContextMappingModel result = parseHelper.parse(dslSnippet);
		// then
		assertThatNoParsingErrorsOccurred(result);
		assertThatNoValidationErrorsOccurred(result);
		
		val UpstreamDownstreamRelationship upstreamDownstreamRelationship = result.map.relationships.get(0) as UpstreamDownstreamRelationship
		assertEquals("RESTful HTTP", upstreamDownstreamRelationship.implementationTechnology);
		assertEquals(DownstreamGovernanceRights.INFLUENCER, upstreamDownstreamRelationship.downstreamGovernanceRights);
		assertEquals("agg1", upstreamDownstreamRelationship.upstreamExposedAggregates.get(0).name);
	}

}
