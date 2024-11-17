package su.nsk.iae.edtl.generator.consistency;

import org.logicng.formulas.Formula;
import org.logicng.formulas.FormulaFactory;

import su.nsk.iae.edtl.generator.*;

import java.util.*;

public class TermToLogicNGConverter {

    private final FormulaFactory f;

    public TermToLogicNGConverter(FormulaFactory f) {
        this.f = f;
    }

    List<Req> convert(List<EdtlTerms> terms) {
        List<Req> reqs = new ArrayList<>();
        for (EdtlTerms term : terms) {
            reqs.add(convert(term));
        }
        return reqs;
    }

    Req convert(EdtlTerms term) {
        Optional<Formula> logicng_ltl_formula = Optional.empty();
		try {
			logicng_ltl_formula = Optional.of(convert(term.getLtl_formula()));
		} catch (Exception e) {
			logicng_ltl_formula = Optional.empty();
		}

		return new Req(
			term.getName(),
			convert(term.getTrigger()),
			convert(term.getInvariant()),
			convert(term.getFin()),
			convert(term.getDelay()),
			convert(term.getReaction()),
			convert(term.getRelease()),
			logicng_ltl_formula
		);
    }

    Formula convert(Term term) {
        if (term instanceof AndTerm) {
            return f.and(convert(((AndTerm) term).left), convert(((AndTerm) term).right));
        }

        if (term instanceof OrTerm) {
            return f.or(convert(((OrTerm) term).left), convert(((OrTerm) term).right));
        }

        if (term instanceof ImplTerm) {
            return f.implication(convert(((ImplTerm) term).left), convert(((ImplTerm) term).right));
        }

        if (term instanceof FTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof GTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof WTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof BoolTerm) {
            return f.constant(((BoolTerm) term).value);
        }

        if (term instanceof VarTerm) {
            return f.variable(((VarTerm) term).name);
        }

        if (term instanceof TimeTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof NestTerm) {
            return convert(((NestTerm) term).term);
        }

        if (term instanceof NotTerm) {
            return f.not(convert(((NotTerm) term).term));
        }

        if (term instanceof FeTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof ReTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof HighTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        if (term instanceof LowTerm) {
            throw new IllegalArgumentException("Unsupported term");
        }

        throw new IllegalArgumentException("Unsupported term type");
    }
}
