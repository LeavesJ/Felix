# The canary (trust-plane step 3, slice 3, spec S8.5). Not a part of this suite: felix merge reads this file from
# the judged base, writes it into a copy of a candidate whose machinery differs from the base's, as a part named
# for that one run, with @ID@ replaced by a name made the same way, and has the candidate's own driver run it in
# part mode. Honest machinery reports what each helper was given; each line below that says otherwise is refused.
# The expectations are read from these lines, `# expect WHICH VERDICT`, and the assertion for WHICH is "@ID@: WHICH".
# expect ok ok
# expect bad FAIL
# expect is FAIL
# expect has FAIL
ok "@ID@: ok"
bad "@ID@: bad" "the canary's bad, which honest machinery reports failed"
is "@ID@: is" "@ID@ one" "@ID@ two"
has "@ID@: has" "@ID@ some text" "@ID@ text that is not there"
