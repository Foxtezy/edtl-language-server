package su.nsk.iae.edtl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import su.nsk.iae.edtl.edtl.Model
import su.nsk.iae.edtl.edtl.Expression
import su.nsk.iae.edtl.edtl.Abbr
import su.nsk.iae.edtl.edtl.PrimaryExpression
import su.nsk.iae.edtl.edtl.XorExpression
import su.nsk.iae.edtl.edtl.AndExpression
import su.nsk.iae.edtl.edtl.UnExpression
import su.nsk.iae.edtl.edtl.Macros
import java.util.HashMap
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*

import com.opencsv.CSVWriter
import java.io.StringWriter
import su.nsk.iae.edtl.edtl.impl.ExpressionImpl
import su.nsk.iae.edtl.edtl.impl.PrimaryExpressionImpl
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import java.util.Objects
import java.util.regex.Pattern
import java.util.Map
import java.time.Duration
import java.time.temporal.TemporalUnit
import su.nsk.iae.edtl.edtl.DeclVarInput
import su.nsk.iae.edtl.edtl.VarDeclaration
import org.eclipse.emf.common.util.EList
import su.nsk.iae.edtl.edtl.DeclVarOutput
import su.nsk.iae.edtl.edtl.Requirement
import java.util.List

class CGenerator {
	def generateCCode(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context){
		val ast = resource.allContents.
					toIterable.
					filter(Model).
					get(0)
		fsa.generateFile(
                "verification.c",
                compile(ast))
	}
	
	private def compile(Model ast)'''
		«compileIncludes()»
		
		«compileTimeFunctions()»
		
		«compileEdtlOperators()»
		
		«compileVars(ast.declVarInput, ast.declVarOutput)»
		
		«compileRequirementCheckContext()»
		
		«compileGeneralRequirementCheckFunction()»
		
		«compileSpecificRequirementCheckFunctions(ast.reqs)»
	'''
	
	private def compileIncludes() '''
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
'''
	
	private def compileTimeFunctions() '''
///////////////////////////////////////////////////
///////////////// TIME FUNCTIONS //////////////////
///////////////////////////////////////////////////

#ifdef __WIN32__

#include <time.h>

uint64_t get_epoch_millis() {
    struct timespec ts;
    timespec_get(&ts, TIME_UTC);
    return (uint64_t)ts.tv_sec * 1000 + (uint64_t)ts.tv_nsec / 1000000
}

#else

#include <sys/time.h>

uint64_t get_current_time_millis() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000 + (uint64_t)tv.tv_usec / 1000;
}

#endif
'''
	
	private def compileEdtlOperators() '''
/////////////////////////////////////////////////////
////////////////// EDTL OPERATORS ///////////////////
/////////////////////////////////////////////////////

bool re(bool prev_v, bool v) {
    return !prev_v && v;
}

bool fe(bool prev_v, bool v) {
    return prev_v && !v;
}

bool high(bool prev_v, bool v) {
    return prev_v && v;
}

bool low(bool prev_v, bool v) {
    return !prev_v && !v;
}
'''
	
	private def compileVars(EList<DeclVarInput> input, EList<DeclVarOutput> output){
		var List<VarDeclaration> vars = newArrayList
		
		if (input !== null) {
			for (declVarInput : input) {
				if (declVarInput.varDecls !== null) {
					for (v : declVarInput.varDecls) {
						vars.add(v.copy)
					}
				}
			}
		}
		
		if (output !== null) {
			for (declVarInput : output) {
				if (declVarInput.varDecls !== null) {
					for (v : declVarInput.varDecls) {
						vars.add(v.copy)
					}
				}
			}
		}
		
		compileVariables(vars)
	}
	
	private def compileVariables(List<VarDeclaration> vars) '''
/////////////////////////////////////////
/////////////// VARIABLES ///////////////
/////////////////////////////////////////

typedef struct vars {
	«FOR varDecl : vars»
	bool «varDecl.v.name»;
	«ENDFOR»
} Vars;
	'''
	
	private def compileRequirementCheckContext() '''
//////////////////////////////////////////////////////
///////////// REQUIREMENT CHECK CONTEXT //////////////
//////////////////////////////////////////////////////

typedef struct times {
    uint64_t curr_time;
    uint64_t prog_time;
    uint64_t trigger_time;
    uint64_t final_time;
} Times;

typedef struct requirement {
    bool trigger;
    bool invariant;
    bool final;
    bool delay;
    bool reaction;
    bool release;
} Requirement;

typedef enum state {
    WAIT_TRIGGER,
    WAIT_FINAL,
    WAIT_DELAY
} State;

typedef struct context {
    Vars vars;
    Vars prev_vars;
    bool vars_are_set;
    Times times;
    Requirement requirement;
    State state;
} Context;

Context create_context() {
    return (Context) {
        .vars_are_set = false,
        .times = { .prog_time = get_current_time_millis() },
        .requirement = {},
        .state = WAIT_TRIGGER,
    };
}

void set_vars_to_context(Context* context, Vars vars) {
    if (context->vars_are_set) {
        context->prev_vars = context->vars;
        context->vars = vars;
    } else {
        context->vars = context->prev_vars = vars;
        context->vars_are_set = true;
    }
}

void reset_context(Context* context) {
    context->times = (Times) { .prog_time = context->times.prog_time };
    context->requirement = (Requirement) {};
    context->state = WAIT_TRIGGER;
}
'''

	private def compileGeneralRequirementCheckFunction() '''
////////////////////////////////////////////////////////////////
///////////// GENERAL REQUIREMENT CHECK FUNCTION ///////////////
////////////////////////////////////////////////////////////////

typedef enum result {
    SUCCESS,
    FAIL,
    CONTINUE
} Result;

Result check_requirement(Context* context, void (*calculate_requirement_attributes)(Context*)) {
    Times* times = &context->times;
    Requirement* requirement = &context->requirement;
    times->curr_time = get_current_time_millis();

    switch (context->state) {
        case WAIT_TRIGGER: {
            calculate_requirement_attributes(context);
            if (!requirement->trigger) {
                return CONTINUE;
            }

            context->state = WAIT_FINAL;
            times->trigger_time = times->curr_time;
        }

        case WAIT_FINAL: {
            calculate_requirement_attributes(context);
            if (requirement->release) {
                return SUCCESS;
            }

            if (!requirement->final) {
                if (requirement->invariant) {
                    return CONTINUE;
                }

                return FAIL;
            }

            context->state = WAIT_DELAY;
            times->final_time = times->curr_time;
        }

        case WAIT_DELAY: {
            calculate_requirement_attributes(context);
            if (requirement->release) {
                return SUCCESS;
            }

            if (requirement->delay) {
                if (!requirement->invariant) {
                    return FAIL;
                }

                if (!requirement->reaction) {
                    return FAIL;
                }

                return SUCCESS;
            }

            if (!requirement->invariant) {
                return FAIL;
            }

            if (requirement->reaction) {
                return SUCCESS;
            }

            return CONTINUE;
        }
    }

    return FAIL;
}
'''

	private def compileSpecificRequirementCheckFunctions(EList<Requirement> reqs) '''
	//////////////////////////////////////////////////////////////////
	///////////// SPECIFIC REQUIREMENT CHECK FUNCTIONS ///////////////
	//////////////////////////////////////////////////////////////////

	«IF reqs !== null»
		«FOR req : reqs»
			«compileSpecificRequirementCheckFunction(req)»
		«ENDFOR»
	«ENDIF»
	'''
	

	private def compileSpecificRequirementCheckFunction(Requirement req) '''
void calculate_attributes_for_«req.name»(Context* context) {
    Vars* vars = &context->vars;
    Vars* prev_vars = &context->prev_vars;
    Times* times = &context->times;
    Requirement* req = &context->requirement;

    switch (context->state) {
        case WAIT_DELAY: {
            req->delay = «convertDelayToCharSequence(req.delayExpr)»
            req->reaction = «convertReactionToCharSequence(req.reacExpr)»
        }

        case WAIT_FINAL: {
            req->invariant = «convertInvariantToCharSequence(req.invExpr)»
            req->final = «convertFinalToCharSequence(req.finalExpr)»
            req->release = «convertReleaseToCharSequence(req.relExpr)»
        }

        case WAIT_TRIGGER: {
            req->trigger = «convertTriggerToCharSequence(req.trigExpr)»
        }
    }
}

Result check_requirement_«req.name»(Context* context) {
    return check_requirement(context, calculate_attributes_for_«req.name»);
}

'''
	
	private def convertTriggerToCharSequence(Expression expr) {
		var trigger = ExprToTermConverter.convertOrDefault(expr, Attribute.TRIGGER, new BoolTerm(true))
		convertTermToCharSequence(trigger, false)
	}
	
	private def convertInvariantToCharSequence(Expression expr) {
		var invariant = ExprToTermConverter.convertOrDefault(expr, Attribute.INVARIANT, new BoolTerm(true))
		convertTermToCharSequence(invariant, false)
	}
	
	private def convertFinalToCharSequence(Expression expr) {
		var fin = ExprToTermConverter.convertOrDefault(expr, Attribute.FINAL, new BoolTerm(false))
		convertTermToCharSequence(fin, false)
	}
	
	private def convertDelayToCharSequence(Expression expr) {
		var delay = ExprToTermConverter.convertOrDefault(expr, Attribute.DELAY, new BoolTerm(false))
		convertTermToCharSequence(delay, false)
	}
	
	private def convertReactionToCharSequence(Expression expr) {
		var reaction = ExprToTermConverter.convertOrDefault(expr, Attribute.REACTION, new BoolTerm(true))
		convertTermToCharSequence(reaction, false)
	}
	
	private def convertReleaseToCharSequence(Expression expr) {
		var release = ExprToTermConverter.convertOrDefault(expr, Attribute.RELEASE, new BoolTerm(false))
		convertTermToCharSequence(release, false)
	}

	private def convertTermToCharSequence(Term term, Boolean needParentheses)'''
	«convertTermToStringWithSemicolon(term, needParentheses)»
	'''
	
	private def convertTermToStringWithSemicolon(Term term, Boolean needParentheses) {
		return convertTermToString(term, needParentheses, false) + ";"
	}
	
	private def String convertTermToString(Term term, Boolean needParentheses, Boolean usePrevVars) {
		if (term instanceof OrTerm) {
			var orString = convertTermToString(term.left, true, usePrevVars) + " || " + convertTermToString(term.right, true, usePrevVars)
			return needParentheses ? "(" + orString + ")" : orString
		}
		if (term instanceof AndTerm) {
			var andString = convertTermToString(term.left, true, usePrevVars) + " && " + convertTermToString(term.right, true, usePrevVars)
			return needParentheses ? "(" + andString + ")" : andString
		}
		if (term instanceof BoolTerm) {
			return String.valueOf(term.value)
		}
		if (term instanceof VarTerm) {
			return (usePrevVars ? "prev_vars->" : "vars->") + term.name
		}
		if (term instanceof NotTerm) {
			return "!" + convertTermToString(term.term, true, usePrevVars)
		}
		if (term instanceof FeTerm) {
			return "fe(" + convertTermToString(term.term, false, true) + ", " + convertTermToString(term.term, false, false) + ")"
		}
		if (term instanceof ReTerm) {
			return "re(" + convertTermToString(term.term, false, true) + ", " + convertTermToString(term.term, false, false) + ")"
		}
		if (term instanceof HighTerm) {
			return "high(" + convertTermToString(term.term, false, true) + ", " + convertTermToString(term.term, false, false) + ")"
		}
		if (term instanceof LowTerm) {
			return "low(" + convertTermToString(term.term, false, true) + ", " + convertTermToString(term.term, false, false) + ")"
		}
		if (term instanceof TimeTerm) {
			return buildTimeIntervalString(term.interval, term.attribute, needParentheses)
		}
		if (term instanceof NestTerm) {
			return convertTermToString(term.term, needParentheses, usePrevVars)
		}
	}
	
	private def String buildTimeIntervalString(String timeInterval, Attribute attribute, Boolean needParentheses) {
		var timeIntervalMillis = TimeIntervalParser.parseTimeIntervalToMillis(timeInterval)
		
		var timeValue = switch (attribute) {
			case TRIGGER: "times->prog_time"
			case INVARIANT: "times->trigger_time"
			case FINAL: "times->trigger_time"
			case DELAY: "times->final_time"
			case REACTION: "times->final_time"
			case RELEASE: "times->trigger_time"
		}
		
		var timeIntervalString = "times->curr_time >= " + timeValue + " + " + timeIntervalMillis
		return needParentheses ? "(" + timeIntervalString + ")" : timeIntervalString
	}
}