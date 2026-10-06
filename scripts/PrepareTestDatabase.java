import java.nio.file.*;
import java.sql.*;
import java.util.Properties;

/** Creates an isolated fixture DB once. Never resets an existing database. */
public class PrepareTestDatabase {
    public static void main(String[] args) throws Exception {
        String host = System.getenv().getOrDefault("DB_HOST", "localhost");
        String port = System.getenv().getOrDefault("DB_PORT", "3306");
        Properties properties = new Properties();
        properties.setProperty("user", System.getenv().getOrDefault("TEST_DB_USERNAME", "root"));
        properties.setProperty("password", System.getenv().getOrDefault("TEST_DB_PASSWORD", "1234"));
        try (Connection connection = DriverManager.getConnection("jdbc:mysql://" + host + ":" + port
                + "/?allowPublicKeyRetrieval=true&useSSL=false&characterEncoding=UTF-8", properties)) {
            try (PreparedStatement exists = connection.prepareStatement(
                    "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'techstore_test'")) {
                if (exists.executeQuery().next()) {
                    System.out.println("techstore_test already exists; left unchanged.");
                    return;
                }
            }
            for (String name : new String[]{"schema.sql", "seed.sql"}) {
                String sql = Files.readString(Path.of(args[0], "database", name));
                sql = sql.replace("techstore_db", "techstore_test").replaceAll("(?m)^--.*$", "");
                if (name.equals("seed.sql")) {
                    sql = sql.replace("'2026-01-01 00:00:00'", "DATE_SUB(NOW(), INTERVAL 1 DAY)")
                             .replace("'2026-12-31 23:59:59'", "DATE_ADD(NOW(), INTERVAL 1 YEAR)");
                }
                for (String statement : sql.split(";")) {
                    if (!statement.isBlank()) try (Statement command = connection.createStatement()) {
                        command.execute(statement);
                    }
                }
            }
            System.out.println("Created and seeded techstore_test. Development data was not changed.");
        }
    }
}
