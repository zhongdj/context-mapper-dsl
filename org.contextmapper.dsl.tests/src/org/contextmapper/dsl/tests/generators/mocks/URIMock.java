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
package org.contextmapper.dsl.tests.generators.mocks;

import org.eclipse.emf.common.util.URI;

public class URIMock extends URI {

	private String filename;
	private String extension;

	public URIMock(String filenameWithoutExt, String fileExtension) {
		super(0);
		this.filename = filenameWithoutExt;
		this.extension = fileExtension;
	}

	@Override
	public URI trimFileExtension() {
		return this;
	}

	@Override
	public String lastSegment() {
		return filename;
	}

}
