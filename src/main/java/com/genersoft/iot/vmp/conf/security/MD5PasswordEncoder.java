package com.genersoft.iot.vmp.conf.security;

import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.util.DigestUtils;

/**
 * MD5密码编码器
 * 用于兼容数据库中存储的MD5密码
 */
@Slf4j
public class MD5PasswordEncoder implements PasswordEncoder {

    @Override
    public String encode(CharSequence rawPassword) {
        return DigestUtils.md5DigestAsHex(rawPassword.toString().getBytes());
    }

    @Override
    public boolean matches(CharSequence rawPassword, String encodedPassword) {
        if (rawPassword == null || encodedPassword == null) {
            log.debug("密码验证失败：rawPassword或encodedPassword为空");
            return false;
        }
        // rawPassword已经是MD5格式（前端发送的），encodedPassword也是MD5格式（数据库存储的）
        // 直接比较两个MD5值
        String rawStr = rawPassword.toString();
        String encodedStr = encodedPassword.toString();
        
        // 如果rawPassword已经是32位MD5字符串，直接比较
        if (rawStr.length() == 32 && encodedStr.length() == 32) {
            boolean match = rawStr.equalsIgnoreCase(encodedStr);
            log.debug("MD5密码比较：raw={}, encoded={}, match={}", rawStr, encodedStr, match);
            return match;
        }
        
        // 否则对rawPassword进行MD5加密后比较
        String encoded = DigestUtils.md5DigestAsHex(rawStr.getBytes());
        boolean match = encoded.equalsIgnoreCase(encodedStr);
        log.debug("MD5密码加密后比较：raw={}, encoded={}, match={}", encoded, encodedStr, match);
        return match;
    }
}

