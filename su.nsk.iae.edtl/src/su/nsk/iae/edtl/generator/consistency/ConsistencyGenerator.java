package su.nsk.iae.edtl.generator.consistency;

import com.opencsv.CSVWriter;

import org.eclipse.xtext.generator.IFileSystemAccess2;
import org.logicng.formulas.Formula;
import org.logicng.formulas.FormulaFactory;
import org.logicng.util.Pair;
import su.nsk.iae.edtl.generator.*;

import java.io.StringWriter;
import java.util.*;
import java.util.stream.Collectors;

public class ConsistencyGenerator {

    private final StringWriter csvStringWriter = new StringWriter();
    private final CSVWriter csvWriter = new CSVWriter(csvStringWriter);
    private final FormulaFactory f = new FormulaFactory();
    private final TermToLogicNGConverter termToLogicNGConverter = new TermToLogicNGConverter(f);


    public void generate(List<EdtlTerms> terms, IFileSystemAccess2 fsa) {
        List<Req> reqs = termToLogicNGConverter.convert(terms);
        List<String> reqNames = reqs.stream().map(Req::name).collect(Collectors.toList());
        reqNames.add(0, " ");
        csvWriter.writeNext(reqNames.toArray(String[]::new));
        var consistMap = checkConsistency(terms);
        for (var entry : consistMap.entrySet()) {
            List<String> line = new ArrayList<>();
            line.add(entry.getKey());
            line.addAll(entry.getValue().stream().map(p -> p.second().answer().name()).collect(Collectors.toList()));
            csvWriter.writeNext(line.toArray(String[]::new));
        }
        //System.out.println(csvStringWriter.toString());
        fsa.generateFile("consistency_output.csv", csvStringWriter.toString());
    }

    public Map<String, List<Pair<String, Result>>> checkConsistency(List<EdtlTerms> terms) {
        List<Req> reqs = termToLogicNGConverter.convert(terms);
        Map<String, List<Pair<String, Result>>> ret = new LinkedHashMap<>();
        for (int i = 0; i < reqs.size(); i++) {
            ret.put(reqs.get(i).name(), new ArrayList<>());
            for (int j = 0; j < reqs.size(); j++) {
                ret.get(reqs.get(i).name()).add(new Pair<>(reqs.get(j).name(), decide(reqs.get(i), reqs.get(j))));
            }
        }
        return ret;
    }

    private Result decide(Req req1, Req req2) {
        if (!req1.trigger().implies(req2.trigger()) && !req2.trigger().implies(req1.trigger())) {
            return new Result(Answer.UNKNOWN);
        }

        if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isTautology()) {
            return new Result(Answer.UNKNOWN);
        } else if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isContradiction()) {
            return new Result(Answer.INCONSISTENT, "Because this requirement is not achivable");
        }

        if (req2.substituteFormula().isPresent() && req2.substituteFormula().get().isTautology()) {
            return new Result(Answer.UNKNOWN);
        } else if (req2.substituteFormula().isPresent() && req2.substituteFormula().get().isContradiction()) {
            return new Result(Answer.INCONSISTENT, "Because that requirement is not achivable");
        }

        if (req1.trigger().implies(req2.trigger())) {
            return compare(req1, req2);
        } else if (req2.trigger().implies(req1.trigger())) {
            return compare(req2, req1);
        }


        return new Result(Answer.UNKNOWN);
    }

    private Result compare(Req req1, Req req2) {
        Formula trg = f.or(f.and(req1.trigger(), f.not(req1.release())), req1.invariant(), f.and(req2.trigger(), f.not(req2.release())));

        // 1
        if (f.and(
                f.not(f.and(req1.invariant(), req2.invariant())),
                f.implication(trg, req1.release()),
                f.implication(trg, f.and(req1.fin(), req1.reaction())),
                f.not(f.implication(trg, f.or(req2.release(), f.and(req2.fin(), req2.reaction()))))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because invariant1 and invariant2 are inconsistent");
        }

        // 2
        if (f.and(
                f.not(f.and(req1.release(), req2.invariant())),
                f.implication(trg, req1.release()),
                f.not(f.implication(trg, f.or(req2.release(), f.and(req2.fin(), req2.reaction()))))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because release1 and invariant2 are inconsistent");
        }

        // 3
        if (f.and(
                f.not(f.and(f.and(req1.fin(), req1.reaction()), req2.invariant())),
                f.implication(trg, f.and(req1.fin(), req1.reaction())),
                f.not(f.implication(trg, f.or(req2.release(), f.and(req2.fin(), req2.reaction()))))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because (final1 ∧ reaction1) and invariant2 are inconsistent");
        }
        
        // 4
        if (f.and(
                f.implication(req1.release(), req2.fin()),
                f.not(f.and(req1.release(), req2.invariant())),
                f.not(f.implication(f.or(req1.release(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because release1 and invariant2 are inconsistent");
        }

        // 5
        if (f.and(
                f.implication(req1.reaction(), req2.fin()),
                f.not(f.and(req1.reaction(), req2.invariant())),
                f.not(f.implication(f.or(req1.reaction(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because reaction1 and invariant2 are inconsistent");
        }

        // 6
        if (f.and(
                f.implication(req1.fin(), req2.fin()),
                f.not(f.and(req1.fin(), req2.invariant())),
                f.not(f.implication(f.or(req1.fin(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "because final1 and invariant2 are inconsistent");
        }

        // 7
        if (f.and(
                f.implication(req1.fin(), req2.fin()),
                f.not(f.and(req1.invariant(), f.not(req2.delay()))),
                f.not(f.and(f.or(req1.invariant(), req1.fin()), req2.release())),
                f.not(f.and(f.or(req1.invariant(), req1.fin()), req2.reaction()))
        ).isTautology()) {
            return new Result(Answer.INCONSISTENT, "bacause invariant1 and not delay2 are inconsistent");
        }

        // CONSISTENT
        if (f.and(
                f.implication(req1.invariant(), req2.invariant()),
                f.implication(req1.fin(), req2.fin()),
                f.implication(req1.delay(), req2.delay()),
                f.implication(req1.reaction(), req2.reaction()),
                f.implication(req1.release(), req2.release())
        ).isTautology()) {
            return new Result(Answer.CONSISTENT);
        }

        return new Result(Answer.UNKNOWN);
    }

}