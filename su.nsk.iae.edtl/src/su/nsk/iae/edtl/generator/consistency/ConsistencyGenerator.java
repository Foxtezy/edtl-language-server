package su.nsk.iae.edtl.generator.consistency;

import com.opencsv.CSVWriter;

import org.eclipse.xtext.generator.IFileSystemAccess2;
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
            line.addAll(entry.getValue().stream().map(p -> p.second().name()).collect(Collectors.toList()));
            csvWriter.writeNext(line.toArray(String[]::new));
        }
        //System.out.println(csvStringWriter.toString());
        fsa.generateFile("consistency_output.csv", csvStringWriter.toString());
    }

    public Map<String, List<Pair<String, Answer>>> checkConsistency(List<EdtlTerms> terms) {
        List<Req> reqs = termToLogicNGConverter.convert(terms);
        Map<String, List<Pair<String, Answer>>> ret = new LinkedHashMap<>();
        for (int i = 0; i < reqs.size(); i++) {
            ret.put(reqs.get(i).name(), new ArrayList<>());
            for (int j = 0; j < reqs.size(); j++) {
                ret.get(reqs.get(i).name()).add(new Pair<>(reqs.get(j).name(), decide(reqs.get(i), reqs.get(j))));
            }
        }
        return ret;
    }

    private Answer decide(Req req1, Req req2) {
        if (!req1.trigger().implies(req2.trigger()) && !req2.trigger().implies(req1.trigger())) {
            return Answer.UNKNOWN;
        }

        if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isTautology()) {
            return Answer.UNKNOWN;
        } else if (req1.substituteFormula().isPresent() && req1.substituteFormula().get().isContradiction()) {
            return Answer.INCONSISTENT;
        }

        if (req2.substituteFormula().isPresent() && req2.substituteFormula().get().isTautology()) {
            return Answer.UNKNOWN;
        } else if (req2.substituteFormula().isPresent() && req2.substituteFormula().get().isContradiction()) {
            return Answer.INCONSISTENT;
        }

        if (req1.trigger().implies(req2.trigger())) {
            return compare(req1, req2);
        } else if (req2.trigger().implies(req1.trigger())) {
            return compare(req2, req1);
        }


        return Answer.UNKNOWN;
    }

    private Answer compare(Req req1, Req req2) {
        // 13
        if (f.and(f.implication(req1.reaction(), req2.fin()),
                f.not(f.and(req1.reaction(), req2.invariant())),
                f.not(f.implication(f.or(req2.fin(), req1.reaction()), f.or(req2.reaction(), req2.release())))).isTautology()) {
            return Answer.INCONSISTENT;
        }
        return Answer.UNKNOWN;
    }

}