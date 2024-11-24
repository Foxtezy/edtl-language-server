package su.nsk.iae.edtl.generator.consistency;

public class Result {
    private final Answer answer;
    private final String explanation;

    public Result(Answer answer) {
        this.answer = answer;
        this.explanation = "";
    }

    public Result(Answer answer, String explanation) {
        this.answer = answer;
        this.explanation = explanation;
    }

    public Answer answer() {
        return answer;
    }

    public String explanation() {
        return explanation;
    }
}
