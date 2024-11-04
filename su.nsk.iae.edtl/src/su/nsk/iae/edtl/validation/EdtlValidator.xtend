/*
 * generated by Xtext 2.25.0
 */
package su.nsk.iae.edtl.validation

import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.validation.Check
import su.nsk.iae.edtl.edtl.EdtlPackage
import su.nsk.iae.edtl.edtl.Variable
import su.nsk.iae.edtl.edtl.Model


import static extension org.eclipse.xtext.EcoreUtil2.*
import su.nsk.iae.edtl.edtl.Expression
import su.nsk.iae.edtl.edtl.AndExpression
import su.nsk.iae.edtl.edtl.UnExpression
import su.nsk.iae.edtl.edtl.DeclVarInput
import su.nsk.iae.edtl.edtl.DeclVarOutput
import su.nsk.iae.edtl.edtl.VarDeclaration
import java.util.ArrayList
import java.util.HashSet
import su.nsk.iae.edtl.edtl.Abbr
import su.nsk.iae.edtl.edtl.Requirement
import su.nsk.iae.edtl.edtl.Macros
import su.nsk.iae.edtl.edtl.PrimaryExpression
import su.nsk.iae.edtl.edtl.VarAssign
import su.nsk.iae.edtl.edtl.GlobInterval
import java.util.Arrays
import java.util.regex.PatternSyntaxException

class EdtlValidator extends AbstractEdtlValidator {
	
	val ePackage = EdtlPackage.eINSTANCE


/* ======================= START REPETITION CHECKS ======================= */
	@Check
	def checkVariable_VarDeclarationRepetition(Variable ele){
		val model = ele.getContainerOfType(Model)
		if (model.declVarInput.checkVarRepetition_DeclVarInput(ele) ||
			model.declVarOutput.checkVarRepetition_DeclVarOutput(ele)
		){
			error("Variable name is duplicated", ePackage.crossVarAbbr_Name)
			return
		}
	}
	
	private def checkVarRepetition_DeclVarInput(EList<DeclVarInput> declVarInputs, Variable ele) {
		return declVarInputs.stream.anyMatch([x | x.varDecls.checkVarRepetiotion_VarDeclaration(ele)])
	}
	
	private def checkVarRepetition_DeclVarOutput(EList<DeclVarOutput> declVarOutputs, Variable ele) {
		return declVarOutputs.stream.anyMatch([x | x.varDecls.checkVarRepetiotion_VarDeclaration(ele)])
	}
	
	private def checkVarRepetiotion_VarDeclaration(EList<VarDeclaration> varDecls, Variable ele) {
		varDecls.stream.map([x | x.v]).anyMatch([x | (x !== ele) &&
			x.name.equals(ele.name)
		])
	}
	
	@Check
	def checkRequirement_RequirementRepetition(Requirement ele){
		val model = ele.getContainerOfType(Model)
		if (model.reqs.checkRequirementRepetition(ele)){
			error("Requirement name is duplicated", ePackage.requirement_Name)
			return
		}
	}
	
	private def checkRequirementRepetition(EList<Requirement> reqs, Requirement ele) {
		reqs.stream.anyMatch([x | (x !== ele) &&
			x.name.equals(ele.name)
		])
	}
	
	@Check
	def checkAbbr_AbbrRepetition(Abbr ele){
		val model = ele.getContainerOfType(Model)
		if (model.abbrs.checkAbbrRepetition(ele)){
			error("Abbr name is duplicated", ePackage.crossVarAbbr_Name)
			return
		}
	}
	
	private def checkAbbrRepetition(EList<Abbr> abbrs, Abbr ele) {
		abbrs.stream.anyMatch([x | (x !== ele) &&
			x.name.equals(ele.name)
		])
	}
	
	@Check
	def checkMacros_MacrosRepetition(Macros ele){
		val model = ele.getContainerOfType(Model)
		if (model.macroses.checkMacrosRepetition(ele)){
			error("Macros name is duplicated", ePackage.macros_Name)
			return
		}
	}
	
	private def checkMacrosRepetition(EList<Macros> macroses, Macros ele) {
		macroses.stream.anyMatch([x | (x !== ele) &&
			x.name.equals(ele.name)
		])
	}
	
/* ======================= END REPETITION CHECKS ======================= */

/* ======================= START INTERVAL CHECKS ======================= */

	@Check
	def checkGlobInterval_IsZero(GlobInterval interval){
        var timeInterval = interval.globInterval.interval.trim()
        try {
        	var String[] timeValues = timeInterval.split("\\D+")
        	var long sum = Arrays.stream(timeValues)
                .mapToLong([String timeValue | Long.valueOf(timeValue)])
                .sum()
        	if (sum == 0) {
            	error("Division by zero", ePackage.globInterval_GlobInterval)
				return
        	}
        } catch (PatternSyntaxException e) {
        	error("Invalid time", ePackage.globInterval_GlobInterval)
        }
	}

/* ======================= END INTERVAL CHECKS ======================= */

/* ======================= START NAME CONFLICT CHECKS ======================= */
	
	/* VARIABLES */
	
	@Check
	def checkNameConflicts(Variable ele){
		val model = ele.getContainerOfType(Model)
		if (model.checkNameConflictsVariable(ele.name)){
			error("Name conflicts", ePackage.crossVarAbbr_Name)
			return
		}
	}
			
	private def boolean checkNameConflictsVariable(Model model, String name){
		return model.abbrs.checkNameConflicts_Abbr(name) ||
		model.macroses.checkNameConflicts_Macros(name) ||
		model.reqs.checkNameConflicts_Req(name)
	}
	
	private def boolean checkNameConflicts_Abbr(EList<Abbr> abbrs, String name){
		abbrs.stream.map([x | x.name]).anyMatch([x | x.equals(name)])
	}
	
	private def boolean checkNameConflicts_Macros(EList<Macros> macroses, String name){
		macroses.stream.map([x | x.name]).anyMatch([x | x.equals(name)])
	}
	
	private def boolean checkNameConflicts_Req(EList<Requirement> reqs, String name){
		reqs.stream.map([x | x.name]).anyMatch([x | x.equals(name)])
	}
	
	@Check
	def checkNameConflicts(Requirement ele){
		val model = ele.getContainerOfType(Model)
		if (model.checkNameConflicts_Req(ele.name)){
			error("Name conflicts", ePackage.requirement_Name)
			return
		}
	}
	
	private def boolean checkNameConflicts_Req(Model model, String name){
		return model.abbrs.checkNameConflicts_Abbr(name) ||
		model.macroses.checkNameConflicts_Macros(name) ||
		model.checkNameConflicts_Variable(name)
	}
	
	private def boolean checkNameConflicts_Variable(Model model, String name){
		return model.declVarInput.checkNameConflicts_DeclVarInput(name) ||
		model.declVarOutput.checkNameConflicts_DeclVarOutput(name)
	}
	
	private def boolean checkNameConflicts_DeclVarInput(EList<DeclVarInput> varDecls, String name){
		return varDecls.stream.anyMatch([x | x.varDecls.checkNameConflicts_VarDeclaration(name)])
	}
	
	private def boolean checkNameConflicts_DeclVarOutput(EList<DeclVarOutput> varDecls, String name){
		return varDecls.stream.anyMatch([x | x.varDecls.checkNameConflicts_VarDeclaration(name)])
	}
	
	private def boolean checkNameConflicts_VarDeclaration(EList<VarDeclaration> varDecls, String name){
		varDecls.stream.map([x | x.v]).anyMatch([x | x.name.equals(name)])
	}

	/* ABBRS */
	
	@Check
	def checkNameConflicts(Abbr ele){
		val model = ele.getContainerOfType(Model)
		if (model.checkNameConflicts_Abbr(ele.name)){
			error("Name conflicts", ePackage.crossVarAbbr_Name)
			return
		}
	}
	
	private def boolean checkNameConflicts_Abbr(Model model, String name){
		return model.reqs.checkNameConflicts_Req(name) ||
		model.macroses.checkNameConflicts_Macros(name) ||
		model.checkNameConflicts_Variable(name)
	}
	
	/* MACROSES */
	
	@Check
	def checkNameConflicts(Macros ele){
		val model = ele.getContainerOfType(Model)
		if (model.checkNameConflicts_Macros(ele.name)){
			error("Name conflicts", ePackage.macros_Name)
			return
		}
	}
	
	private def boolean checkNameConflicts_Macros(Model model, String name){
		return model.reqs.checkNameConflicts_Req(name) ||
		model.abbrs.checkNameConflicts_Abbr(name) ||
		model.checkNameConflicts_Variable(name)
	}
	
/* ======================= END NAME CONFLICT CHECKS ======================= */

/* ======================= START VAR ASSIGN CKECKS ======================= */

	@Check
	def checkVariable_Assign(VarAssign ele){
		if (ele.variable.getContainerOfType(VarDeclaration).type.equals('BOOL')){
			if (!(ele.value.equals('TRUE') || ele.value.equals('FALSE'))){
				error("Wrong value", ePackage.varAssign_Value)
			}
		}
		if (ele.variable.getContainerOfType(VarDeclaration).type.equals('INT')){
			if (ele.value.equals('TRUE') || ele.value.equals('FALSE')){
				error("Wrong value", ePackage.varAssign_Value)
			}
		}
	}

/* ======================= END VAR ASSIGN CKECKS ======================= */

/* ======================= START ABBR CKECKS ======================= */

	@Check
	def checkAbbr_Expressions(PrimaryExpression ele){
		val model = ele.getContainerOfType(Model)
		if (model.abbrs.checkAbbrs_ExpressionMacrosesAbbrs(ele)){
			error("Macroses and Abbrs in abbreviations are not available", ePackage.primaryExpression_Macros)
			return
		}
	}
	
	private def boolean checkAbbrs_ExpressionMacrosesAbbrs(EList<Abbr> abbrs, PrimaryExpression ele){
		return abbrs.stream.anyMatch([x | x.expr.hasMacroses(ele) || x.expr.hasAbbrs(ele)])
	}
	
	private def boolean hasAbbrs(Expression expr, PrimaryExpression ele){
		val abbr = ele.getV()
		if (abbr === null || abbr instanceof Variable){
			return false
		}
		
		if (abbr instanceof Abbr){
			if (expr.eCrossReferences.contains(abbr)){
				return true
			}	else {
				return checkAbbrs_AbbrTraversal(expr.left, abbr as Abbr) || 
			checkAbbrs_AbbrTraversal(expr.right, abbr as Abbr)
			}
		} else {
			return false
		}
		
	}
	
	private def boolean checkAbbrs_AbbrTraversal(Expression expr, Abbr abbr){
		if (expr === null){
			return false
		}
		if (expr.eCrossReferences.contains(abbr)){
			return true
		} else {
			return checkAbbrs_AbbrTraversal(expr.left, abbr) || 
			checkAbbrs_AbbrTraversal(expr.right, abbr)
		}
	}
	
	private def boolean hasMacroses(Expression expr, PrimaryExpression ele){
		val macros = ele.getMacros()
		if (macros === null){
			return false
		}
		
		if (expr.eCrossReferences.contains(macros)) {
			return true
		} else {
			return checkAbbrs_MacrosTraversal(expr.left, macros) || 
			checkAbbrs_MacrosTraversal(expr.right, macros)
		}
	}
	
	private def boolean checkAbbrs_MacrosTraversal(Expression expr, Macros macros){
		if (expr === null){
			return false
		}
		if (expr.eCrossReferences.contains(macros)){
			return true
		} else {
			return checkAbbrs_MacrosTraversal(expr.left, macros) || 
			checkAbbrs_MacrosTraversal(expr.right, macros)
		}
	}

/* ======================= END ABBR CHECKS ======================= */

/* ======================= START USE CKECKS ======================= */

	@Check
	def checkSymbolicVariable_NeverUse(Variable ele) {
		val model = ele.getContainerOfType(Model)
		if (!hasCrossReferences(model, ele)) {
			warning("Variable is never used", ePackage.crossVarAbbr_Name)
		}
	}
	
	private def boolean hasCrossReferences(EObject context, EObject target) {
		val targetSet = new HashSet<EObject>()
		targetSet.add(target)
		val res = new ArrayList<EReference>()
		val EcoreUtil2.ElementReferenceAcceptor acceptor = 
			[EObject referrer, EObject referenced, EReference reference, int index | {
				res.add(reference)
			}]
		context.findCrossReferences(targetSet, acceptor)
		return !res.isEmpty()
	}
	
	@Check
	def checkAvailabilityOfIntervalForTau(PrimaryExpression ele){
		val tau = ele.getTau()
		if (tau === null) {
			return
		}
		val model = ele.getContainerOfType(Model)
		if (model.globInterval === null) {
			error("INTERVAL must be set", ePackage.primaryExpression_Tau)
		}
		
	}

/* ======================= END USE CKECKS ======================= */

/* ======================= START OPERATION STYLE CKECKS ======================= */
	
	@Check
	def checkOperatorStyle(Model ele) {
		val oprs = new ArrayList<Integer>()
		val pascal = new ArrayList<Integer>()
		val symb = new ArrayList<Integer>()
		
		ele.reqs.stream.anyMatch([x | x.checkOperatorStyle_Req(oprs, pascal, symb)])
		ele.abbrs.stream.anyMatch([x | x.checkOperatorStyle_Abbr(oprs, pascal, symb)])
		ele.macroses.stream.anyMatch([x | x.checkOperatorStyle_Macros(oprs, pascal, symb)])
		
		if (oprs.contains(-1)){
			warning('Write code in one style is recommended', ePackage.model_Reqs)
			warning('Write code in one style is recommended', ePackage.model_Abbrs)
			warning('Write code in one style is recommended', ePackage.model_Macroses)
		}
		
		for (a : oprs){
			if (a.equals(1)){
				pascal.add(a)
			}
			if (a.equals(2)){
				symb.add(a)
			}
		}
		
		if (pascal.size != 0 && symb.size != 0) {
			warning('Write code in one style is recommended', ePackage.model_Reqs)
			warning('Write code in one style is recommended', ePackage.model_Abbrs)
			warning('Write code in one style is recommended', ePackage.model_Macroses)
		}
	}
	
	private def checkOperatorStyle_Abbr(Abbr abbr,
		ArrayList<Integer> oprs, ArrayList<Integer> pascal, ArrayList<Integer> symb
	){
		oprs.add(abbr.expr.checkOperatorStyle_Traversal(false, false))
	}
	
	private def checkOperatorStyle_Macros(Macros macros,
		ArrayList<Integer> oprs, ArrayList<Integer> pascal, ArrayList<Integer> symb
	){
		oprs.add(macros.expr.checkOperatorStyle_Traversal(false, false))
	}

	private def checkOperatorStyle_Req(Requirement req, 
		ArrayList<Integer> oprs, ArrayList<Integer> pascal, ArrayList<Integer> symb
	){
		oprs.add(req.trigExpr.checkOperatorStyle_Traversal(false, false))
		oprs.add(req.invExpr.checkOperatorStyle_Traversal(false, false))
		oprs.add(req.finalExpr.checkOperatorStyle_Traversal(false, false))
		oprs.add(req.delayExpr.checkOperatorStyle_Traversal(false, false))
		oprs.add(req.reacExpr.checkOperatorStyle_Traversal(false, false))
		oprs.add(req.relExpr.checkOperatorStyle_Traversal(false, false))
	}
	
	private def int checkOperatorStyle_Traversal(Expression expr,
		boolean isPascalStyle, boolean isSymbStyle){
		
		var pascal = isPascalStyle
		var symb = isSymbStyle
		
		if (isPascalStyle && isSymbStyle){
			return -1
		}
		
		if (expr === null){
			if (isPascalStyle) {
				return 1
			}
			if (isSymbStyle){
				return 2
			}
			return 0
		}
		
		switch (expr.orOp){
			case('OR'): pascal = true
			
			case('||'): symb = true
		}
		
		if (expr instanceof UnExpression) {
			var unExpr = expr as UnExpression
			switch(unExpr.unOp){
				case('NOT'): pascal = true
				
				case('!'): symb = true
			}
		}	

		if (expr instanceof AndExpression){
		var andExpr = expr as AndExpression
			switch(andExpr.andOp){
				case('AND'): pascal = true
				
				case('&&'): symb = true
			}
		}
		
		val l = expr.left.checkOperatorStyle_Traversal(pascal, symb)
		val r = expr.right.checkOperatorStyle_Traversal(pascal, symb)
				
		if (l === -1 || r === -1) {
			return -1
		}
		if (l === 1 && r === 1){
			return 1
		}
		if (l === 2 && r === 2){
			return 2
		}
		if (l === 0){
			return r
		}
		if (r === 0){
			return l
		} else {
			return -1
		}	
	}
}
/* ======================= END OPERATION STYLE CKECKS ======================= */