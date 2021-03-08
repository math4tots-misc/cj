package www.emu.chip8

import cj.net.HTTP
import cj.Math
import cj.Error
import www.dom.Window
import cj.Uint8Array
import www.emu.chip8.C8Speaker
import www.emu.chip8.C8Keyboard
import www.emu.chip8.C8Renderer

class C8CPU {
    static var printed = false
    static val sprites = [
        0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
        0x20, 0x60, 0x20, 0x20, 0x70, # 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
        0x90, 0x90, 0xF0, 0x10, 0x10, # 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
        0xF0, 0x10, 0x20, 0x40, 0x40, # 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, # A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
        0xF0, 0x80, 0x80, 0x80, 0xF0, # C
        0xE0, 0x90, 0x90, 0x90, 0xE0, # D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
        0xF0, 0x80, 0xF0, 0x80, 0x80, # F
    ]
    val renderer: C8Renderer
    val keyboard: C8Keyboard
    val speaker: C8Speaker
    val memory: Uint8Array = Uint8Array.withSize(4096) # 4096 bytes of memory
    val v: Uint8Array = Uint8Array.withSize(16) # 16 8-bit registers
    var i = 0 # 16-bit register to store memory addresses
    var delayTimer = 0
    var soundTimer = 0
    var pc = 0x200
    val stack: List[Int] = []
    var paused = false
    var speed = 10

    def reset(self) {
        for i = 0; i < memory.size(); i++ {
            memory[i] = 0
        }
        for i = 0; i < v.size(); i++ {
            v[i] = 0
        }
        delayTimer = 0
        soundTimer = 0
        pc = 0x200
        while stack { stack.pop() }
        paused = false
    }

    def loadSpritesIntoMemory(self) {
        for i = 0; i < sprites.size(); i++ {
            memory[i] = sprites[i]
        }
    }

    def loadProgramIntoMemory(self, program: Uint8Array) {
        for i = 0; i < program.size(); i++ {
            memory[0x200 + i] = program[i]
        }
    }

    def cycle(self) {
        for i = 0; i < speed; i++ {
            if not paused {
                val opcode = memory[pc] << 8 | memory[pc + 1]
                executeInstruction(opcode)
            }
        }
        if not paused {
            if delayTimer { delayTimer-- }
            if soundTimer { soundTimer-- }
        }
        if soundTimer { speaker.play(440) } else { speaker.stop() }
    }

    private def executeInstruction(self, opcode: Int) {
        pc += 2
        val x = (opcode & 0x0F00) >> 8 # lower 4 bits of the high byte
        val y = (opcode & 0x00F0) >> 4 # upper 4 bits of the low byte
        switch opcode & 0xF000 {
            case 0x0000 {
                switch opcode {
                    case 0x00E0 = renderer.clear() # CLS (clear screen)
                    case 0x00EE { pc = stack.pop() } # RET (return)
                    else = ()
                }
            }
            case 0x1000 { pc = opcode & 0xFFF } # JP (jump)
            case 0x2000 { stack.add(pc); pc = opcode & 0xFFF } # CALL
            case 0x3000 { if v[x] == opcode & 0xFF { pc += 2 } } # SE Vx,byte
            case 0x4000 { if v[x] != opcode & 0xFF { pc += 2 } } # SNE Vx,byte
            case 0x5000 { if v[x] == v[y] { pc += 2 } } # SE Vx,Vy
            case 0x6000 { v[x] = opcode & 0xFF } # LD Vx,byte
            case 0x7000 { v[x] = v[x] + (opcode & 0xFF) } # ADD Vx,byte
            case 0x8000 {
                switch opcode & 0xF {
                    case 0x0 { v[x] = v[y] } # LD Vx,Vy
                    case 0x1 { v[x] = v[x] | v[y] } # OR Vx,Vy
                    case 0x2 { v[x] = v[x] & v[y] } # AND Vx,Vy
                    case 0x3 { v[x] = v[x] ^ v[y] } # XOR Vx,Vy
                    case 0x4 {
                        # ADD Vx,Vy
                        val sum = v[x] + v[y]
                        v[0xF] = if sum > 0xFF { 1 } else { 0 }
                        v[x] = sum
                    }
                    case 0x5 {
                        # SUB Vx,Vy
                        v[0xF] = if v[x] > v[y] { 1 } else { 0 }
                        v[x] = v[x] - v[y]
                    }
                    case 0x6 {
                        # SHR Vx{,Vy}
                        v[0xF] = v[x] & 0x1
                        v[x] = v[x] >> 1
                    }
                    case 0x7 {
                        # SUBN Vx,Vy
                        v[0xF] = if v[y] > v[x] { 1 } else { 0 }
                        v[x] = v[y] - v[x]
                    }
                    case 0xE {
                        # SHL Vx{,Vy}
                        v[0xF] = v[x] & 0x80
                        v[x] = v[x] << 1
                    }
                }
            }
            case 0x9000 { if v[x] != v[y] { pc += 2 } } # SNE Vx,Vy
            case 0xA000 { i = opcode & 0xFFF } # LD I,addr
            case 0xB000 { pc = (opcode & 0xFFF) + v[0] } # JP V0,addr
            case 0xC000 {
                # RND Vx,byte
                val rand = Math.floor(Math.random() * 0xFF)
                v[x] = rand & (opcode & 0xFF)
            }
            case 0xD000 {
                # DRW Vx,Vy,nibble
                val width = 8
                val height = opcode & 0xF
                v[0xF] = 0
                for row = 0; row < height; row++ {
                    var sprite = memory[i + row]
                    for col = 0; col < width; col++ {
                        if (sprite & 0x80) > 0 {
                            if renderer.togglePixel(v[x] + col, v[y] + row) {
                                v[0xF] = 1
                            }
                        }
                        sprite = sprite << 1
                    }
                }
            }
            case 0xE000 {
                switch opcode & 0xFF {
                    case 0x9E { if keyboard.isKeyPressed(v[x]) { pc += 2 } } # SKP Vx
                    case 0xA1 { if not keyboard.isKeyPressed(v[x]) { pc += 2 } } # SKNP Vx
                }
            }
            case 0xF000 {
                switch opcode & 0xFF {
                    case 0x07 { v[x] = delayTimer } # LD Vx,DT
                    case 0x0A {
                        # LD Vx,K
                        paused = true
                        keyboard.onNextKeyPress = key -> {
                            v[x] = key
                            paused = false
                        }
                    }
                    case 0x15 { delayTimer = v[x] } # LD DT,Vx
                    case 0x18 { soundTimer = v[x] } # LD ST,Vx
                    case 0x1E { i += v[x] } # ADD I,Vx
                    case 0x29 { i = v[x] * 5 } # LD F,Vx-ADD I,Vx
                    case 0x33 {
                        # LD B,Vx
                        memory[i] = v[x] // 100
                        memory[i + 1] = (v[x] % 100) // 10
                        memory[i + 2] = v[x] % 10
                    }
                    case 0x55 {
                        # LD [I],Vx
                        for registerIndex = 0; registerIndex <= x; registerIndex++ {
                            memory[i + registerIndex] = v[registerIndex]
                        }
                    }
                    case 0x65 {
                        # LD Vx,[I]
                        for registerIndex = 0; registerIndex <= x; registerIndex++ {
                            v[registerIndex] = memory[i + registerIndex]
                        }
                    }
                }
            }
            else = throw Error("Unknown opcode " + opcode);
        }
    }
}
