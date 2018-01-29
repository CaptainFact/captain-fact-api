#!/usr/bin/env bash

#!/bin/bash
counter=$((1))
$@
while [ $? -eq 0 ]; do
    $@
    counter=$((counter+1))
done

echo "Failed after $counter attempts"