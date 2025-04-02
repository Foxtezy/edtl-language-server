package su.nsk.iae.edtl.generator.consistency;

import java.util.List;

public class Result {
    private final Answer answer;
    private final List<String> explanation;

    public Result(Answer answer) {
        this.answer = answer;
        this.explanation = List.of();
    }

    public Result(Answer answer, String explanation) {
        this.answer = answer;
        this.explanation = List.of(explanation);
    }

    public Result(Answer answer, List<String> explanation) {
        this.answer = answer;
        this.explanation = explanation;
    }

    public Answer answer() {
        return answer;
    }

    public List<String> explanation() {
        return explanation;
    }
}
