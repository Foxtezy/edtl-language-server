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
        for (var entry : consistMap.sequencedEntrySet()) {
            List<String> line = new ArrayList<>();
            line.add(entry.getKey());
            line.addAll(entry.getValue().sequencedEntrySet().stream().map(e -> e.getValue().answer().name()).collect(Collectors.toList()));
            csvWriter.writeNext(line.toArray(String[]::new));
        }
        fsa.generateFile("consistency_output.csv", csvStringWriter.toString());
    }

    public SequencedMap<String, SequencedMap<String, Result>> checkConsistency(List<EdtlTerms> terms) {
        List<Req> reqs = termToLogicNGConverter.convert(terms);
        SequencedMap<String, SequencedMap<String, Result>> ret = new LinkedHashMap<>();

        for (Req req : reqs) {
            ret.put(req.name(), new LinkedHashMap<>());
        }

        for (int i = 0; i < reqs.size(); i++) {
            for (int j = i; j < reqs.size(); j++) {
                if (i == j) {
                    Result res = decide(reqs.get(i));
                    ret.get(reqs.get(i).name()).put(reqs.get(i).name(), res);
                } else {
                    Result res = decide(reqs.get(i), reqs.get(j));
                    ret.get(reqs.get(i).name()).put(reqs.get(j).name(), res);
                    ret.get(reqs.get(j).name()).put(reqs.get(i).name(), res);
                }
            }
        }

        return ret;
    }

    private Result decide(Req req) {
        if (req.substituteFormula().isPresent() && req.substituteFormula().get().isContradiction()) {
            return new Result(Answer.INCONSISTENT, "Because this requirement is not achivable");
        }
        return new Result(Answer.CONSISTENT);
    }

    private Result decide(Req req1, Req req2) {
        if (!req1.trigger().implies(req2.trigger()) && !req2.trigger().implies(req1.trigger())) {
            return new Result(Answer.UNKNOWN);
        }

        if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isTautology()) {
            return new Result(Answer.CONSISTENT);
        } else if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isContradiction()) {
            return new Result(Answer.INCONSISTENT, "Because this requirement is not achivable");
        }

        if (req2.substituteFormula().isPresent() && req2.substituteFormula().get().isTautology()) {
            return new Result(Answer.CONSISTENT);
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
        Answer answer = Answer.UNKNOWN;
        List<String> explanation = new ArrayList<>();

        // 1
        if (f.and(
                f.not(f.and(req1.invariant(), req2.invariant())),
                f.not(f.implication(trg, f.and(req1.fin(), req1.reaction()))),
                f.not(f.implication(trg, f.and(req2.fin(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("1 because invariant1 and invariant2 are inconsistent");
        }

        // 2
        if (f.and(
                f.not(f.and(req1.release(), req2.invariant())),
                f.not(f.implication(trg, f.and(req2.fin(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("2 because release1 and invariant2 are inconsistent");
        }

        // 3
        if (f.and(
                f.not(f.and(f.and(req1.fin(), req1.reaction()), req2.invariant())),
                f.not(f.implication(trg, f.and(req2.fin(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("3 because (final1 ∧ reaction1) and invariant2 are inconsistent");
        }
        
        // 4
        if (f.and(
                f.implication(req1.release(), req2.fin()),
                f.not(f.and(req1.release(), req2.invariant())),
                f.not(f.implication(f.or(req1.release(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("4 because release1 and invariant2 are inconsistent");
        }

        // 5
        if (f.and(
                f.implication(req1.reaction(), req2.fin()),
                f.not(f.and(req1.reaction(), req2.invariant())),
                f.not(f.implication(f.or(req1.reaction(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("5 because reaction1 and invariant2 are inconsistent");
        }

        // 6
        if (f.and(
                f.implication(req1.fin(), req2.fin()),
                f.not(f.and(req1.fin(), req2.invariant())),
                f.not(f.implication(f.or(req1.fin(), req2.fin()), f.or(req2.release(), req2.reaction())))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("6 because final1 and invariant2 are inconsistent");
        }

        // 7
        if (f.and(
                f.implication(req1.fin(), req2.fin()),
                f.not(f.and(req1.invariant(), f.not(req2.delay()))),
                f.not(f.and(f.or(req1.invariant(), req1.fin()), req2.release())),
                f.not(f.and(f.or(req1.invariant(), req1.fin()), req2.reaction()))
        ).isTautology()) {
            answer = Answer.INCONSISTENT;
            explanation.add("7 bacause invariant1 and not delay2 are inconsistent");
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

        return new Result(answer, explanation);
    }

}