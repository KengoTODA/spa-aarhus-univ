Introduction
============

Static program analysis aims to automatically answer questions about the possible behaviors of programs. In this chapter, we explain why this can be useful
and interesting, and we discuss the basic characteristics of analysis tools.

1.1 Applications of Static Program Analysis
-------------------------------------------

Static program analysis has been used since the early 1960’s in optimizing compilers. More recently, it has proven useful also for bug finding and verification
tools, and in IDEs to support program development. In the following, we give
some examples of the kinds of questions about program behavior that arise in
these different applications.

**Analysis for program optimization** Optimizing compilers (including just-intime compilers in interpreters) need to know many different properties of the
program being compiled, in order to generate efficient code. A few examples of
such properties are:

* Does the program contain dead code, or more specifically, is function :math:`f` unreachable from main? If so, the code size can be reduced.
* Is the value of some expression inside a loop the same in every iteration? If so, the expression can be moved outside the loop to avoid redundant computations.
* Does the value of variable :math:`x` depend on the program input? If not, it could be precomputed at compile time.
* What are the lower and upper bounds of the integer variable :math:`x`? The answer may guide the choice of runtime representation of the variable.
* Do :math:`p` and :math:`q` point to disjoint data structures in memory? That may enable parallel processing.

**Analysis for program correctness** The most successful analysis tools that have
been designed to detect errors (or verify absence of errors) target generic correctness properties that apply to most or all programs written in specific programming languages. In unsafe languages like C, such errors sometimes lead to
critical security vulnerabilities. In more safe languages like Java, such errors are
typically less severe, but they can still cause program crashes. Examples of such
properties are:

* Does there exist an input that leads to a null pointer dereference, divisionby-zero, or arithmetic overflow?
* Are all variables initialized before they are read?
* Are arrays always accessed within their bounds?
* Can there be dangling references, i.e., use of pointers to memory that has been freed?
* Does the program terminate on every input? Even in reactive systems such as operating systems, the individual software components, for example device driver routines, are expected to always terminate.

Other correctness properties depend on specifications provided by the programmer for the individual programs (or libraries), for example:

* Are all assertions guaranteed to succeed? Assertions express program specific correctness properties that are supposed to hold in all executions.
* Is function hasNext always called before function next, and is open always called before read? Many libraries have such so-called typestate correctness properties.
* Does the program throw an ActivityNotFoundException or a SQLiteException for some input?

With web and mobile software, information flow correctness properties have
become extremely important:

* Can input values from untrusted users flow unchecked to file system operations? This would be a violation of *integrity*.
* Can secret information become publicly observable? Such situations are violations of *confidentiality*.

The increased use of concurrency (parallel or distributed computing) and eventdriven execution models gives rise to more questions about program behavior:

* Are data races possible? Many errors in multi-threaded programs are cause by two threads using a shared resource without proper synchronization.
* Can the program (or parts of the program) deadlock? This is often a concern for multi-threaded programs that use locks for synchronization.

**Analysis for program development** Modern IDEs perform various kinds of
program analysis to support debugging, refactoring, and program understanding. This involves questions, such as:

* Which functions may possibly be called on line 117, or conversely, where can function :math:`f` possibly be called from? Function inlining and other refactorings rely on such information.
* At which program points could :math:`x` be assigned its current value? Can the value of variable :math:`x` affect the value of variable :math:`y`? Such questions often arise when programmers are trying to understand large codebases and during debugging when investigating why a certain bug appears.
* What types of values can variable :math:`x` have? This kind of question often arises with programming languages where type annotations are optional or entirely absent, for example OCaml, JavaScript, or Python.

1.2 Approximative Answers
-------------------------

Regarding correctness, programmers routinely use testing to gain confidence that their programs work as intended, but as famously stated by Dijkstra [Dij70]:
*“Program testing can be used to show the presence of bugs, but never to show their absence.”*
Ideally we want guarantees about what our programs may do for all possible inputs, and we want these guarantees to be provided automatically, that is, by programs.
A *program analyzer* is such a program that takes other programs as input and decides whether or not they have a certain property.

Reasoning about the behavior of programs can be extremely difficult, even
for small programs. As an example, does the following program code terminate
on every integer input n (assuming arbitrary-precision integers)?

::

    while (n > 1) {
      if (n % 2 == 0) // if n is even, divide it by two
        n = n / 2;
      else // if n is odd, multiply by three and add one
        n = 3 * n + 1;
    }

In 1937, Collatz conjectured that the answer is “yes”. As of 2017, the conjecture
has been checked for all inputs up to 87·2\ :superscript:`60`\  but nobody has been able to prove it for all inputs [Roo19].
Even straight-line programs can be difficult to reason about. Does the following program output true for some integer inputs?

::

    x = input; y = input; z = input;
    output x*x*x + y*y*y + z*z*z == 42;

This was an open problem since 1954 until 2019 when the answer was found
after over a million hours of computing [BS19].

Rice’s theorem [Ric53] is a general result from 1953 which informally states that all interesting questions about the input/output behavior of programs (written in Turing-complete programming languages [1]_ ) are *undecidable*.
This is easily seen for any special case. Assume for example the existence of an analyzer that decides if a variable in a program has a constant value in any execution.
In other words, the analyzer is a program A that takes as input a program :math:`T`, one of :math:`T`’s variables :math:`x`, and some value :math:`k`, and decides whether or not :math:`x`’s value is always equal to :math:`k` whenever :math:`T` is executed.

.. [1] From this point on, we only consider Turing complete languages.

.. 図形

We could then exploit this analyzer to also decide the halting problem by using as input the following program where :math:`TM(J)` simulates the :math:`j`’th Turing machine on empty input:

::

    x = 17; if (TM(j)) x = 18;

Here :math:`x` has a constant value :math:`17` if and only if the :math:`j`’th Turing machine does not halt on empty input.
If the hypothetical constant-value analyzer :math:`A` exists, then we have a decision procedure for the halting problem, which is known to be impossible [Tur37].

At first, this seems like a discouraging result, however, this theoretical result does not prevent *approximative* answers.
While it is impossible to build an analysis that would correctly decide a property for any analyzed program, it is often possible to build analysis tools that give useful answers for most realistic programs.
As the ideal analyzer does not exist, there is always room for building more precise approximations (which is colloquially called the *full employment theorem for static program analysis designers*).

Approximative answers may be useful for finding bugs in programs, which may be viewed as a weak form of program verification. As a case in point, consider programming with pointers in the C language.
This is fraught with dangers such as ``null`` dereferences, dangling pointers, leaking memory, and unintended aliases. Ordinary compilers offer little protection from pointer errors.
Consider the following small program which may perform every kind of error:

::

    int main(int argc, char *argv[]) {
      if (argc == 42) {
        char *p,*q;
        p = NULL;
        printf("%s",p);
        q = (char *)malloc(100);
        p = q;
        free(q);
        *p = ’x’;
        free(p);
        p = (char *)malloc(100);
        p = (char *)malloc(100);
        q = p;
        strcat(p,q);
        assert(argc > 87);
      }
    }

Standard compiler tools such as gcc ``-Wall`` detect no errors in this program.
Finding the errors by testing might miss the errors (for this program, no errors are encountered unless we happen to have a test case that runs the program with exactly 42 arguments).
However, if we had even approximative answers to questions about ``null`` values, pointer targets, and branch conditions then many of the above errors could be caught statically, without actually running the program.

.. topic:: Exercise 1.1

    Describe all the pointer-related errors in the above program.

Ideally, the approximations we use are *conservative* (or safe), meaning that all errors lean to the same side, which is determined by our intended application.
As an example, approximating the memory usage of programs is conservative if the estimates are never lower than what is actually possible when the programs are executed.
Conservative approximations are closely related to the concept of soundness of program analyzers.
We say that a program analyzer is *sound* if it never gives incorrect results (but it may answer *maybe*).
Thus, the notion of soundness depends on the intended application of the analysis output, which may cause some confusion. For example, a verification tool is typically called sound if it never misses any errors of the kinds it has been designed to detect, but it is allowed to produce spurious warnings (also called false positives), whereas an automated testing tool is called sound if all reported errors are genuine, but it may miss errors.

Program analyses that are used for optimizations typically require soundness.
If given false information, the optimization may change the semantics of the
program. Conversely, if given trivial information, then the optimization fails to
do anything.

Consider again the problem of determining if a variable has a constant value.
If our intended application is to perform constant propagation optimization, then the analysis may only answer *yes* if the variable really is a constant and must answer *maybe* if the variable may or may not be a constant.
The trivial solution is of course to answer maybe all the time, so we are facing the engineering challenge of answering *yes* as often as possible while obtaining a reasonable analysis performance.

.. 図形

In the following chapters we focus on techniques for computing approximations that are conservative with respect to the semantics of the programming language.
The theory of semantics-based abstract interpretation presented in Chapter 11 provides a solid mathematical framework for reasoning about analysis soundness and precision.
Although soundness is a laudable goal in analysis design, modern analyzers for real programming languages often cut corners by sacrificing soundness to obtain better precision and performance, for example when modeling reflection in Java [LSS\ :superscript:`+`\15].

1.3 Undecidability of Program Correctness
-----------------------------------------

.. 以下マークアップまだ

(This section requires familiarity with the concept of universal Turing machines; it is not a prerequisite for the following chapters.)

The reduction from the halting problem presented above shows that some static analysis problems are undecidable.
However, halting is often the least of the concerns programmers have about whether their programs work correctly.
For example, if we wish to ensure that the programs we write cannot crash with null pointer errors, we may be willing to assume that the programs do not also have problems with infinite loops.

Using a diagonalization argument we can show a very strong result: It is impossible to build a static program analysis that can decide whether a given program may fail when executed.
Moreover, this result holds even if the analysis is only required to work for programs that halt on all inputs.
In other words, the halting problem is not the only obstacle; approximation is inevitably necessary.

If we model programs as deterministic Turing machines, program failure can be modeled using a special *fail* state [2]_.
That is, on a given input, a Turing machine will eventually halt in its accept state (intuitively returning “yes”), in its reject state (intuitively returning “no”), in its fail state (meaning that the correctness condition has been violated), or the machine diverges (i.e., never halts).
A Turing machine is *correct* if its fail state is unreachable.

We can show the undecidability result using an elegant proof by contradiction.
Assume :math:`P` is a program that can decide whether or not any given total Turing machine is correct.
(If the input to :math:`P` is not a total Turing machine, :math:`P`’s output is unspecified – we only require it to correctly analyze Turing machines that always halt.)
Let us say that :math:`P` halts in its accept state if and only if the given Turing machine is correct, and it halts in the reject state otherwise.
Our goal is to show that :math:`P` cannot exist.

.. [2] Technically, we here restrict ourselves to safety properties; liveness properties can be addressed similarly using other models of computability.

If :math:`P` exists, then we can also build another Turing machine, let us call it :math:`M`, that takes as input the encoding :math:`e(T)` of a Turing machine :math:`T` and then builds the encoding :math:`e(S_T)` of yet another Turing machine :math:`S_T` , which behaves as follows:
:math:`S_T` is essentially a universal Turing machine that is specialized to simulate :math:`T` on input :math:`e(T)`.
Let :math:`w` denote the input to :math:`S_T` .
Now :math:`S_T` is constructed such that it simulates :math:`T` on input :math:`e(T)` for at most :math:`|w|` moves.
If the simulation ends in :math:`T`’s accept state, then :math:`S_T` goes to its fail state.
It is obviously possible to create :math:`S_T` in such a way that this is the only way it can reach its fail state.
If the simulation does not end in :math:`T`’s accept state (that is, :math:`|w|` moves have been made, or the simulation reaches :math:`T`’s reject or fail state), then :math:`S_T` goes to its accept state or its reject state (which one we choose does not matter).
This completes the explanation of how :math:`S_T` works relative to :math:`T` and :math:`w`.
Note that :math:`S_T` never diverges, and it reaches its fail state if and only if `T` accepts input :math:`e(T)` after at most :math:`|w|` moves.
After building :math:`e(S_T)`, :math:`M` passes it to our hypothetical program analyzer :math:`P`.
Assuming that :math:`P` works as promised, it ends in accept if :math:`S_T` is correct, in which case we also let :math:`M` halt in its accept state, and in reject otherwise, in which case :math:`M` similarly halts in its reject state.

.. 図形

We now ask: Does :math:`M` accept input :math:`e(M)`? That is, what happens if we run :math:`M` with :math:`T` = :math:`M`?
If :math:`M` does accept input :math:`e(M)`, it must be the case that :math:`P` accepts input :math:`e(S_T)`, which in turn means that :math:`e(S_T)` is correct, so its fail state is unreachable.
In other words, for any input w, no matter its length, :math:`S_T` does not reach its fail state.
This in turn means that :math:`T` does not accept input :math:`e(T)`.
However, we have :math:`T` = :math:`M`, so this contradicts our assumption that :math:`M` accepts input :math:`e(M)`.
Conversely, if :math:`M` rejects input :math:`e(M)`, then :math:`P` rejects input :math:`e(S_T)`, so the fail state of :math:`S_T` is reachable for some input :math:`v`.
This means that there must exist some w such that the fail state of :math:`S_T` is reached in :math:`|w|` steps on input :math:`v`, so :math:`T` must accept input :math:`e(T)`, and again we have a contradiction.
By construction :math:`M` halts in either accept or reject on any input, but neither is possible for input :math:`e(M)`.
In conclusion, the ideal program correctness analyzer :math:`P` cannot exist.

.. topic:: Exercise 1.2

    In the above proof, the hypothetical program analyzer :math:`P` is only required to correctly analyze programs that always halt.
    Show how the proof can be simplified if we want to prove the following weaker property: There exists no Turing machine :math:`P` that can decide whether or not the fail state is reachable in a given Turing machine.
    (Note that the given Turing machine is now not assumed to be total.)
