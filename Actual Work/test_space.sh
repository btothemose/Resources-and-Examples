#!/bin/bash

test1() {
    test2() {
        echo "test2"
    }
    echo "test1"
}
test3() {
    test2
    echo "test3"
}
test1
test3