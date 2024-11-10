package su.nsk.iae.edtl.generator;

import org.logicng.formulas.Formula;

import java.util.Objects;
import java.util.Optional;

public final class Req {
    private final String name;
    private final Formula trigger;
    private final Formula invariant;
    private final Formula fin;
    private final Formula delay;
    private final Formula reaction;
    private final Formula release;
    private final Optional<Formula> substituteFormula;

    public Req(String name, Formula trigger, Formula invariant, Formula fin, Formula delay, Formula reaction, Formula release,
               Optional<Formula> substituteFormula) {
        this.name = name;
        this.trigger = trigger;
        this.invariant = invariant;
        this.fin = fin;
        this.delay = delay;
        this.reaction = reaction;
        this.release = release;
        this.substituteFormula = substituteFormula;
    }

    public String name() {
        return name;
    }

    public Formula trigger() {
        return trigger;
    }

    public Formula invariant() {
        return invariant;
    }

    public Formula fin() {
        return fin;
    }

    public Formula delay() {
        return delay;
    }

    public Formula reaction() {
        return reaction;
    }

    public Formula release() {
        return release;
    }

    public Optional<Formula> substituteFormula() {
        return substituteFormula;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == this) return true;
        if (obj == null || obj.getClass() != this.getClass()) return false;
        var that = (Req) obj;
        return Objects.equals(this.name, that.name) &&
                Objects.equals(this.trigger, that.trigger) &&
                Objects.equals(this.invariant, that.invariant) &&
                Objects.equals(this.fin, that.fin) &&
                Objects.equals(this.delay, that.delay) &&
                Objects.equals(this.reaction, that.reaction) &&
                Objects.equals(this.release, that.release) &&
                Objects.equals(this.substituteFormula, that.substituteFormula);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, trigger, invariant, fin, delay, reaction, release, substituteFormula);
    }

    @Override
    public String toString() {
        return "Req[" +
                "name=" + name + ", " +
                "trigger=" + trigger + ", " +
                "invariant=" + invariant + ", " +
                "fin=" + fin + ", " +
                "delay=" + delay + ", " +
                "reaction=" + reaction + ", " +
                "release=" + release + ", " +
                "substituteFormula=" + substituteFormula + ']';
    }


}
