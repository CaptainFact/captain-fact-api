import EctoEnum

defenum StatementStatusEnum, :statement_status_enum, [:voting, :terminated]

# Inspired by US military information rating
# see https://en.wikipedia.org/wiki/Intelligence_source_and_information_reliability
defenum TruthinessEnum, :thruthiness_enum, [:confirmed, :probably_true, :possibly_true, :doubtfully_true, :improbable, :cannot_be_judged]
