from datetime import datetime, timezone

import pandas as pd


def to_mysql_ts(ts):

    if ts is not None:
        sql_ts = (
            datetime.fromisoformat(ts[:-1])
            .astimezone(timezone.utc)
            .strftime("%Y-%m-%d %H:%M:%S")
        )
        return sql_ts
    else:
        return None


def update_destination_table(df: pd.DataFrame, table: str, cur) -> None:

    columns = df.columns.tolist()
    placeholders = ", ".join(["%s"] * len(columns))
    col_names = ", ".join(columns)

    for _, row in df.iterrows():
        cur.execute(
            f"""
            INSERT INTO {table} ({col_names})
            VALUES ({placeholders})
        """,
            tuple(row.values),
        )


def clear_destination_table(table: str, cur) -> None:

    cur.execute(f"TRUNCATE TABLE {table};")

# source: https://gitlab.wikimedia.org/repos/data-engineering/wmfdata-python/-/blob/main/src/wmfdata/utils.py?ref_type=heads#L201
# by https://gitlab.wikimedia.org/nshahquinn
def sql_tuple(i):
    """
    Given a Python iterable, returns a string representation that can be used in an SQL IN
    clause.

    For example:
    > sql_tuple(["a", "b", "c"])
    "('a', 'b', 'c')"

    WARNING: In some cases, this function produces incorrect results with strings that contain
    single quotes or backslashes. If you encounter this situation, consult the code comments or ask
    the maintainers for help.
    """

    if type(i) != list:
        i = [x for x in i]

    if len(i) == 0:
        raise ValueError("Cannot produce an SQL tuple without any items.")

    list_repr = repr(i)
    return "(" + list_repr[1:-1] + ")"