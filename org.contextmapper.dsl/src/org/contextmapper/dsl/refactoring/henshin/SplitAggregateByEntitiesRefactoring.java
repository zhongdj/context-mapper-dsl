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
package org.contextmapper.dsl.refactoring.henshin;

import java.util.List;
import java.util.stream.Collectors;

import org.contextmapper.dsl.contextMappingDSL.Aggregate;
import org.contextmapper.dsl.contextMappingDSL.BoundedContext;
import org.contextmapper.dsl.contextMappingDSL.ContextMap;
import org.contextmapper.dsl.contextMappingDSL.ContextMappingModel;
import org.contextmapper.dsl.contextMappingDSL.Module;
import org.contextmapper.dsl.contextMappingDSL.Relationship;
import org.contextmapper.dsl.contextMappingDSL.UpstreamDownstreamRelationship;
import org.contextmapper.tactic.dsl.tacticdsl.DomainObject;
import org.contextmapper.tactic.dsl.tacticdsl.SimpleDomainObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.henshin.interpreter.UnitApplication;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.xbase.lib.IteratorExtensions;

import com.google.common.collect.Iterators;

public class SplitAggregateByEntitiesRefactoring extends AbstractHenshinRefactoring {

	private final static String TEMP_AGGREGATE_NAMES = "TEMP_AR_New_Aggregate";
	private final static String NEW_AGGREGATE_NAME_PREFIX = "NewAggregate";

	private String aggregateName;
	private List<Aggregate> newAggregates;

	public SplitAggregateByEntitiesRefactoring(String aggregateName) {
		this.aggregateName = aggregateName;
	}

	@Override
	protected String getHenshinTransformationFilename() {
		Aggregate selectedAggregate = getSelectedAggregate(model);
		if (selectedAggregate != null && selectedAggregate.eContainer() instanceof Module)
			return HenshinTransformationFileProvider.SPLIT_AGGREGATE_BY_ENTITIES_IN_MODULE;
		return HenshinTransformationFileProvider.SPLIT_AGGREGATE_BY_ENTITIES;
	}

	@Override
	protected String getTransformationUnitName() {
		return "splitAggregateByEntities";
	}

	@Override
	protected void setUnitParameters(UnitApplication refactoringUnit) {
		refactoringUnit.setParameterValue("aggregateName", aggregateName);
		refactoringUnit.setParameterValue("newAggregateName", TEMP_AGGREGATE_NAMES);
	}

	@Override
	protected void throwTransformationError() {
		throw new RuntimeException("Error splitting by aggregate '" + aggregateName + "' ... (Problem with Henshin transformation)");
	}

	@Override
	protected void postProcessing(Resource resource) {
		List<ContextMappingModel> contextMappingModels = IteratorExtensions
				.<ContextMappingModel>toList(Iterators.<ContextMappingModel>filter(resource.getAllContents(), ContextMappingModel.class));
		if (contextMappingModels.size() > 0) {
			Aggregate inputAggregate = getSelectedAggregate(contextMappingModels.get(0));
			if (inputAggregate == null)
				return;
			setAggregateRoot(inputAggregate);
			if (inputAggregate.eContainer() instanceof BoundedContext) {
				BoundedContext bc = (BoundedContext) inputAggregate.eContainer();
				fixNewAggregateNamesAndSetRoot(bc.getAggregates());
			} else if (inputAggregate.eContainer() instanceof Module) {
				Module m = (Module) inputAggregate.eContainer();
				fixNewAggregateNamesAndSetRoot(m.getAggregates());
			}

			addNewAggregatesToExposedAggregatesIfOriginalIsExposed(contextMappingModels.get(0).getMap());
		}

	}

	private void fixNewAggregateNamesAndSetRoot(List<Aggregate> aggregates) {
		newAggregates = aggregates.stream().filter(agg -> agg.getName().equals(TEMP_AGGREGATE_NAMES)).collect(Collectors.toList());
		int i = 1;
		for (Aggregate newAggregate : newAggregates) {
			newAggregate.setName(NEW_AGGREGATE_NAME_PREFIX + i);
			setAggregateRoot(newAggregate);
			i++;
		}
	}

	private void setAggregateRoot(Aggregate aggregate) {
		// after this refactoring, there should only be one entity per aggregate
		if (aggregate.getDomainObjects().size() == 1) {
			SimpleDomainObject object = aggregate.getDomainObjects().get(0);
			if (object instanceof DomainObject)
				((DomainObject) object).setAggregateRoot(true);
		}
	}

	private Aggregate getSelectedAggregate(ContextMappingModel model) {
		List<Aggregate> allAggregates = EcoreUtil2.<Aggregate>getAllContentsOfType(model, Aggregate.class);
		List<Aggregate> aggregatesWithInputName = allAggregates.stream().filter(agg -> agg.getName().equals(aggregateName)).collect(Collectors.toList());
		if (aggregatesWithInputName.isEmpty())
			return null;

		return aggregatesWithInputName.get(0);
	}

	private void addNewAggregatesToExposedAggregatesIfOriginalIsExposed(ContextMap contextMap) {
		if (contextMap == null)
			return;

		for (Relationship relationship : contextMap.getRelationships()) {
			if (!(relationship instanceof UpstreamDownstreamRelationship))
				continue;

			UpstreamDownstreamRelationship upDownRelationship = (UpstreamDownstreamRelationship) relationship;
			if (upDownRelationship.getUpstreamExposedAggregates().stream().map(a -> a.getName()).collect(Collectors.toList()).contains(aggregateName)) {
				upDownRelationship.getUpstreamExposedAggregates().addAll(newAggregates);
			}
		}
	}

}
